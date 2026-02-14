/**
 * n8n External Hooks for OIDC Authentication
 *
 * MODIFICATIONS FROM ORIGINAL (https://github.com/cweagans/n8n-oidc):
 * 1. Disabled normal login - shouldShowNormalLogin() always returns false
 * 2. Removed "Admin? Sign in with email" link from login page
 * 3. Auto-redirect /setup to OIDC login (first OIDC user becomes owner)
 * 4. Find and update n8n's shell owner user instead of creating duplicate owner
 * 5. Set userManagement.isInstanceOwnerSetUp = true when shell owner is updated
 *
 * Original source: https://github.com/cweagans/n8n-oidc
 * Commit: f2961d6c6ac103989f4920523b6d3faad7547bc2
 */

const https = require('https');
const http = require('http');
const crypto = require('crypto');
const { URL, URLSearchParams } = require('url');

const config = {
  issuerUrl: process.env.OIDC_ISSUER_URL,
  clientId: process.env.OIDC_CLIENT_ID,
  clientSecret: process.env.OIDC_CLIENT_SECRET,
  redirectUri: process.env.OIDC_REDIRECT_URI,
  scopes: process.env.OIDC_SCOPES || 'openid email profile',
};

function validateConfig() {
  const missing = [];
  if (!config.issuerUrl) missing.push('OIDC_ISSUER_URL');
  if (!config.clientId) missing.push('OIDC_CLIENT_ID');
  if (!config.clientSecret) missing.push('OIDC_CLIENT_SECRET');
  if (!config.redirectUri) missing.push('OIDC_REDIRECT_URI');
  return missing;
}

let discoveryCache = null;
let discoveryCacheTime = 0;
const DISCOVERY_CACHE_TTL = 3600000;

function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const protocol = parsedUrl.protocol === 'https:' ? https : http;

    const reqOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
      path: parsedUrl.pathname + parsedUrl.search,
      method: options.method || 'GET',
      headers: options.headers || {},
    };

    const req = protocol.request(reqOptions, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body,
        });
      });
    });

    req.on('error', reject);

    if (options.body) {
      req.write(options.body);
    }

    req.end();
  });
}

async function fetchDiscoveryDocument() {
  const now = Date.now();
  if (discoveryCache && now - discoveryCacheTime < DISCOVERY_CACHE_TTL) {
    return discoveryCache;
  }

  const discoveryUrl = config.issuerUrl.replace(/\/$/, '') + '/.well-known/openid-configuration';
  const response = await makeRequest(discoveryUrl);

  if (response.statusCode !== 200) {
    throw new Error(`Failed to fetch OIDC discovery document: ${response.statusCode}`);
  }

  discoveryCache = JSON.parse(response.body);
  discoveryCacheTime = now;
  return discoveryCache;
}

function generateRandomString(length = 32) {
  return crypto.randomBytes(length).toString('hex');
}

function base64UrlEncode(input) {
  const base64 = Buffer.isBuffer(input) ? input.toString('base64') : Buffer.from(input).toString('base64');
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function base64UrlDecode(input) {
  let base64 = input.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) {
    base64 += '=';
  }
  return Buffer.from(base64, 'base64');
}

function decodeJwt(token) {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid JWT format');
  }

  const payload = JSON.parse(base64UrlDecode(parts[1]).toString('utf8'));
  return payload;
}

async function exchangeCodeForTokens(code, discovery) {
  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: config.redirectUri,
    client_id: config.clientId,
    client_secret: config.clientSecret,
  });

  const response = await makeRequest(discovery.token_endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  if (response.statusCode !== 200) {
    console.error('Token exchange failed:', response.body);
    throw new Error(`Token exchange failed: ${response.statusCode}`);
  }

  return JSON.parse(response.body);
}

async function fetchUserInfo(accessToken, discovery) {
  const response = await makeRequest(discovery.userinfo_endpoint, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (response.statusCode !== 200) {
    console.error('UserInfo fetch failed:', response.body);
    throw new Error(`UserInfo fetch failed: ${response.statusCode}`);
  }

  return JSON.parse(response.body);
}

function createSignedCookie(payload, secret, expiresInSeconds = 900) {
  const exp = Math.floor(Date.now() / 1000) + expiresInSeconds;
  const data = JSON.stringify({ ...payload, exp });
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(data);
  const signature = hmac.digest('hex');
  return base64UrlEncode(data) + '.' + signature;
}

function verifySignedCookie(cookie, secret) {
  try {
    const [dataB64, signature] = cookie.split('.');
    const data = base64UrlDecode(dataB64).toString('utf8');

    const hmac = crypto.createHmac('sha256', secret);
    hmac.update(data);
    const expectedSignature = hmac.digest('hex');

    if (signature !== expectedSignature) {
      return null;
    }

    const payload = JSON.parse(data);
    if (payload.exp && payload.exp < Date.now() / 1000) {
      return null;
    }

    return payload;
  } catch {
    return null;
  }
}

function getCookieSecret(context) {
  const baseKey = process.env.N8N_ENCRYPTION_KEY || process.env.OIDC_CLIENT_SECRET || 'n8n-oidc-hook-secret';
  const hash = crypto.createHash('sha256').update(baseKey + '-oidc-state').digest('hex');
  return hash;
}

function createAuthToken(user, jwtService) {
  const payload = {
    id: user.id,
    hash: createUserHash(user),
    usedMfa: false,
  };

  return jwtService.sign(payload, { expiresIn: '7d' });
}

function createUserHash(user) {
  const payload = [user.email, user.password || ''];
  if (user.mfaEnabled && user.mfaSecret) {
    payload.push(user.mfaSecret.substring(0, 3));
  }
  return crypto.createHash('sha256').update(payload.join(':')).digest('base64').substring(0, 10);
}

function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

const N8N_DI_PATH = '/usr/local/lib/node_modules/n8n/node_modules/@n8n/di';
const N8N_JWT_SERVICE_PATH = '/usr/local/lib/node_modules/n8n/dist/services/jwt.service.js';

module.exports = {
  n8n: {
    ready: [
      async function (server, n8nConfig) {
        const missing = validateConfig();
        if (missing.length > 0) {
          console.warn(`[OIDC Hook] Missing configuration: ${missing.join(', ')}. OIDC disabled.`);
          return;
        }

        console.log('[OIDC Hook] Initializing OIDC authentication...');

        const { Container } = require(N8N_DI_PATH);
        const { JwtService } = require(N8N_JWT_SERVICE_PATH);
        const jwtService = Container.get(JwtService);

        const { app } = server;
        const cookieSecret = getCookieSecret();

        const cookieOptions = {
          httpOnly: true,
          secure: process.env.N8N_PROTOCOL === 'https',
          sameSite: 'lax',
          maxAge: 15 * 60 * 1000,
        };

        const authCookieOptions = {
          httpOnly: true,
          secure: process.env.N8N_PROTOCOL === 'https',
          sameSite: 'lax',
          maxAge: 7 * 24 * 60 * 60 * 1000,
        };

        /**
         * Redirect /setup to OIDC login (backend redirect for initial setup)
         */
        app.get('/setup', (req, res) => {
          res.redirect('/auth/oidc/login');
        });

        app.get('/auth/oidc/login', async (req, res) => {
          try {
            const discovery = await fetchDiscoveryDocument();

            const state = generateRandomString();
            const nonce = generateRandomString();

            const stateCookie = createSignedCookie({ state }, cookieSecret);
            const nonceCookie = createSignedCookie({ nonce }, cookieSecret);

            res.cookie('n8n-oidc-state', stateCookie, cookieOptions);
            res.cookie('n8n-oidc-nonce', nonceCookie, cookieOptions);

            const authUrl = new URL(discovery.authorization_endpoint);
            authUrl.searchParams.set('client_id', config.clientId);
            authUrl.searchParams.set('redirect_uri', config.redirectUri);
            authUrl.searchParams.set('response_type', 'code');
            authUrl.searchParams.set('scope', config.scopes);
            authUrl.searchParams.set('state', state);
            authUrl.searchParams.set('nonce', nonce);

            res.redirect(authUrl.toString());
          } catch (error) {
            console.error('[OIDC Hook] Login error:', error);
            res.status(500).send('OIDC configuration error. Please check the logs.');
          }
        });

        app.get('/auth/oidc/callback', async (req, res) => {
          try {
            const { code, state, error, error_description } = req.query;

            if (error) {
              console.error('[OIDC Hook] OIDC error:', error, error_description);
              return res.redirect('/signin?error=' + encodeURIComponent(error_description || error));
            }

            if (!code || !state) {
              return res.redirect('/signin?error=' + encodeURIComponent('Missing authorization code or state'));
            }

            const stateCookie = req.cookies['n8n-oidc-state'];
            const nonceCookie = req.cookies['n8n-oidc-nonce'];

            if (!stateCookie || !nonceCookie) {
              return res.redirect('/signin?error=' + encodeURIComponent('Missing state cookies - session expired'));
            }

            const statePayload = verifySignedCookie(stateCookie, cookieSecret);
            const noncePayload = verifySignedCookie(nonceCookie, cookieSecret);

            if (!statePayload || statePayload.state !== state) {
              return res.redirect('/signin?error=' + encodeURIComponent('Invalid state - possible CSRF attack'));
            }

            res.clearCookie('n8n-oidc-state');
            res.clearCookie('n8n-oidc-nonce');

            const discovery = await fetchDiscoveryDocument();
            const tokens = await exchangeCodeForTokens(code, discovery);

            if (tokens.id_token) {
              const idTokenClaims = decodeJwt(tokens.id_token);
              if (noncePayload && idTokenClaims.nonce !== noncePayload.nonce) {
                return res.redirect('/signin?error=' + encodeURIComponent('Invalid nonce - possible replay attack'));
              }
            }

            let userInfo;
            try {
              userInfo = await fetchUserInfo(tokens.access_token, discovery);
            } catch (e) {
              if (tokens.id_token) {
                userInfo = decodeJwt(tokens.id_token);
              } else {
                throw e;
              }
            }

            if (!userInfo.email || !isValidEmail(userInfo.email)) {
              return res.redirect('/signin?error=' + encodeURIComponent('No valid email in OIDC response'));
            }

            const { User, Settings, Credentials, Workflow } = this.dbCollections;

            let user = await User.findOne({
              where: { email: userInfo.email },
              relations: ['role'],
            });

            // MODIFICATION: Find and update shell owner user instead of creating new owner
            if (!user) {
              const allUsers = await User.find({ relations: ['role'] });
              const shellOwner = allUsers.find(u => u.role?.slug === 'global:owner' && (!u.email || u.email === ''));

              if (shellOwner) {
                shellOwner.email = userInfo.email;
                shellOwner.firstName = userInfo.given_name || userInfo.name?.split(' ')[0] || 'User';
                shellOwner.lastName = userInfo.family_name || userInfo.name?.split(' ').slice(1).join(' ') || '';
                shellOwner.password = crypto.randomBytes(32).toString('hex');
                await User.save(shellOwner);
                user = shellOwner;
                await Settings.save({ key: 'userManagement.isInstanceOwnerSetUp', value: 'true', loadOnStartup: true });
                console.log(`[OIDC Hook] Updated shell owner user with: ${userInfo.email}`);
              } else {
                const userData = {
                  email: userInfo.email,
                  firstName: userInfo.given_name || userInfo.name?.split(' ')[0] || 'User',
                  lastName: userInfo.family_name || userInfo.name?.split(' ').slice(1).join(' ') || '',
                  password: crypto.randomBytes(32).toString('hex'),
                  role: { slug: 'global:member' },
                };

                const result = await User.createUserWithProject(userData);
                user = result.user;

                console.log(`[OIDC Hook] Created member user with personal project: ${userInfo.email}`);
              }
            }

            if (!user) {
              return res.redirect('/signin?error=' + encodeURIComponent('Failed to create or find user'));
            }

            const authToken = createAuthToken(user, jwtService);

            res.cookie('n8n-auth', authToken, authCookieOptions);

            res.redirect('/');
          } catch (error) {
            console.error('[OIDC Hook] Callback error:', error);
            res.redirect('/signin?error=' + encodeURIComponent('Authentication failed: ' + error.message));
          }
        });

        app.get('/assets/oidc-frontend-hook.js', (req, res) => {
          res.type('text/javascript; charset=utf-8');
          res.set('Cache-Control', 'public, max-age=3600');
          res.send(getFrontendScript());
        });

        console.log('[OIDC Hook] OIDC routes registered:');
        console.log('  - GET /setup (redirect to OIDC login)');
        console.log('  - GET /auth/oidc/login');
        console.log('  - GET /auth/oidc/callback');
        console.log('  - GET /assets/oidc-frontend-hook.js');
      },
    ],
  },

  frontend: {
    settings: [
      async function (frontendSettings) {
        const missing = validateConfig();
        if (missing.length > 0) {
          return;
        }

        frontendSettings.sso = frontendSettings.sso || {};
        frontendSettings.sso.oidc = {
          loginEnabled: true,
          loginUrl: '/auth/oidc/login',
          callbackUrl: config.redirectUri,
        };

        frontendSettings.userManagement = frontendSettings.userManagement || {};
        frontendSettings.userManagement.authenticationMethod = 'oidc';

        frontendSettings.enterprise = frontendSettings.enterprise || {};
        frontendSettings.enterprise.oidc = true;

        console.log('[OIDC Hook] Frontend settings configured for OIDC');
      },
    ],
  },
};

function getFrontendScript() {
  return `
(function() {
	'use strict';

	// MODIFICATION: Always disable normal login
	function shouldShowNormalLogin() {
		return false;
	}

	function isSigninPage() {
		return window.location.pathname === '/signin' || window.location.pathname === '/login';
	}

	function displayError(form) {
		var error = new URLSearchParams(window.location.search).get('error');
		if (!error || !form || form.querySelector('#oidc-error')) return;

		var errorDiv = document.createElement('div');
		errorDiv.id = 'oidc-error';
		errorDiv.style.cssText = 'background: var(--color-danger-tint-1, #fee); border: 1px solid var(--color-danger, #fcc); color: var(--color-danger, #c00); padding: 12px; border-radius: 4px; margin: 16px 0;';
		errorDiv.textContent = decodeURIComponent(error);

		var heading = form.querySelector('div[class*="_heading_"]');
		if (heading) heading.after(errorDiv);
		else form.prepend(errorDiv);
	}

	function injectSsoButton() {
		if (shouldShowNormalLogin()) return;
		if (!isSigninPage()) return;

		var form = document.querySelector('[data-test-id="auth-form"]');
		if (!form || form.querySelector('#oidc-sso-button')) return;

		var existingButton = form.querySelector('[data-test-id="form-submit-button"]');
		var buttonClasses = existingButton ? existingButton.className : '';

		form.querySelectorAll('div[class*="_inputsContainer_"], div[class*="_buttonsContainer_"], div[class*="_actionContainer_"]')
			.forEach(function(el) { el.style.display = 'none'; });

		var ssoContainer = document.createElement('div');
		ssoContainer.id = 'oidc-sso-container';
		ssoContainer.style.cssText = 'text-align: center;';

		var button = document.createElement('button');
		button.id = 'oidc-sso-button';
		button.type = 'button';
		button.textContent = 'Sign in with SSO';
		button.onclick = function() { window.location.href = '/auth/oidc/login'; };

		if (buttonClasses) {
			button.className = buttonClasses;
			button.style.width = '100%';
		} else {
			button.style.cssText = 'width: 100%; padding: 12px 24px; font-size: 14px; font-weight: 600; color: white; background: var(--color-primary, #ea4b30); border: none; border-radius: 4px; cursor: pointer;';
		}

		ssoContainer.appendChild(button);
		// MODIFICATION: Removed admin link

		var heading = form.querySelector('div[class*="_heading_"]');
		if (heading) heading.after(ssoContainer);
		else form.prepend(ssoContainer);

		displayError(form);
	}

	// MODIFICATION: Auto-redirect /setup to OIDC login
	function observeAndInject() {
		if (window.location.pathname === '/setup') {
			window.location.href = '/auth/oidc/login';
			return;
		}
		if (shouldShowNormalLogin() || !isSigninPage()) return;

		injectSsoButton();

		var observer = new MutationObserver(function() {
			if (isSigninPage() && !shouldShowNormalLogin()) {
				var form = document.querySelector('[data-test-id="auth-form"]');
				if (form && !form.querySelector('#oidc-sso-button')) {
					injectSsoButton();
				}
			}
		});

		observer.observe(document.body, { childList: true, subtree: true });
		setTimeout(function() { observer.disconnect(); }, 10000);
	}

	function handleNavigation() {
		var origPush = history.pushState;
		var origReplace = history.replaceState;

		history.pushState = function() {
			origPush.apply(this, arguments);
			setTimeout(observeAndInject, 100);
		};

		history.replaceState = function() {
			origReplace.apply(this, arguments);
			setTimeout(observeAndInject, 100);
		};

		window.addEventListener('popstate', function() {
			setTimeout(observeAndInject, 100);
		});
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function() {
			observeAndInject();
			handleNavigation();
		});
	} else {
		observeAndInject();
		handleNavigation();
	}

	setTimeout(observeAndInject, 500);
	setTimeout(observeAndInject, 1000);

	console.log('[OIDC Hook] Frontend customization loaded');
})();
`;
}
