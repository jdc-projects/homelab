# -*- coding: utf-8 -*-
SECRET_KEY = "{{SEAHUB_SECRET_KEY}}"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'seahub_db',
        'USER': 'seafile',
        'PASSWORD': '{{MARIADB_PASSWORD}}',
        'HOST': '{{MARIADB_HOST}}',
        'PORT': '3306',
        'OPTIONS': {'charset': 'utf8mb4'},
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django_pylibmc.memcached.PyLibMCCache',
        'LOCATION': 'memcached:11211',
    },
    'locmem': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    },
}
COMPRESS_CACHE_BACKEND = 'locmem'

# For security consideration, please set to match the host/domain of your site, e.g., ALLOWED_HOSTS = ['.example.com'].
# Please refer https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts for details.
ALLOWED_HOSTS = ['.{{SERVER_BASE_DOMAIN}}']

# Whether to use a secure cookie for the CSRF cookie
# https://docs.djangoproject.com/en/3.2/ref/settings/#csrf-cookie-secure
CSRF_COOKIE_SECURE = True

# The value of the SameSite flag on the CSRF cookie
# https://docs.djangoproject.com/en/3.2/ref/settings/#csrf-cookie-samesite
CSRF_COOKIE_SAMESITE = 'Strict'

# Enalbe or disalbe registration on web. Default is `False`.
ENABLE_SIGNUP = False

# Activate or deactivate user when registration complete. Default is `True`.
# If set to `False`, new users need to be activated by admin in admin panel.
ACTIVATE_AFTER_REGISTRATION = False

# Whether to send email when a system admin adding a new member. Default is `True`.
SEND_EMAIL_ON_ADDING_SYSTEM_MEMBER = False

# Whether to send email when a system admin resetting a user's password. Default is `True`.
SEND_EMAIL_ON_RESETTING_USER_PASSWD = False

# Send system admin notify email when user registration is complete. Default is `False`.
NOTIFY_ADMIN_AFTER_REGISTRATION = False

# Remember days for login. Default is 7
LOGIN_REMEMBER_DAYS = 7

# Attempt limit before showing a captcha when login.
LOGIN_ATTEMPT_LIMIT = 3

# deactivate user account when login attempts exceed limit
# Since version 5.1.2 or pro 5.1.3
FREEZE_USER_ON_LOGIN_FAILED = False

# mininum length for user's password
USER_PASSWORD_MIN_LENGTH = 6

# LEVEL based on four types of input:
# num, upper letter, lower letter, other symbols
# '3' means password must have at least 3 types of the above.
USER_PASSWORD_STRENGTH_LEVEL = 3

# default False, only check USER_PASSWORD_MIN_LENGTH
# when True, check password strength level, STRONG(or above) is allowed
USER_STRONG_PASSWORD_REQUIRED = False

# Force user to change password when admin add/reset a user.
# Added in 5.1.1, deafults to True.
FORCE_PASSWORD_CHANGE = True

# Age of cookie, in seconds (default: 2 weeks).
SESSION_COOKIE_AGE = 60 * 60 * 24 * 7 * 2

# Whether a user's session cookie expires when the Web browser is closed.
SESSION_EXPIRE_AT_BROWSER_CLOSE = False

# Whether to save the session data on every request. Default is `False`
SESSION_SAVE_EVERY_REQUEST = False

# Whether enable the feature "published library". Default is `False`
# Since 6.1.0 CE
ENABLE_WIKI = False

# In old version, if you use Single Sign On, the password is not saved in Seafile.
# Users can't use WebDAV because Seafile can't check whether the password is correct.
# Since version 6.3.8, you can enable this option to let user's to specific a password for WebDAV login.
# Users login via SSO can use this password to login in WebDAV.
# Enable the feature. pycryptodome should be installed first.
# sudo pip install pycryptodome==3.12.0
ENABLE_WEBDAV_SECRET = False
WEBDAV_SECRET_MIN_LENGTH = 8

# LEVEL for the password, based on four types of input:
# num, upper letter, lower letter, other symbols
# '3' means password must have at least 3 types of the above.
WEBDAV_SECRET_STRENGTH_LEVEL = 3

# Since version 7.0.9, you can force a full user to log in with a two factor authentication.
# The prerequisite is that the administrator should 'enable two factor authentication' in the 'System Admin -> Settings' page.
# Then you can add the following configuration information to the configuration file.
ENABLE_FORCE_2FA_TO_ALL_USERS = False

# Turn on this option to let users to add a label to a library snapshot. Default is `False`
ENABLE_REPO_SNAPSHOT_LABEL = False

# if enable create encrypted library
ENABLE_ENCRYPTED_LIBRARY = False

# version for encrypted library
# should only be `2` or `4`.
# version 3 is insecure (using AES128 encryption) so it's not recommended any more.
ENCRYPTED_LIBRARY_VERSION = 4

# mininum length for password of encrypted library
REPO_PASSWORD_MIN_LENGTH = 8

# force use password when generate a share/upload link (since version 8.0.9)
SHARE_LINK_FORCE_USE_PASSWORD = False

# mininum length for password for share link (since version 4.4)
SHARE_LINK_PASSWORD_MIN_LENGTH = 8

# LEVEL for the password of a share/upload link
# based on four types of input:
# num, upper letter, lower letter, other symbols
# '3' means password must have at least 3 types of the above. (since version 8.0.9)
SHARE_LINK_PASSWORD_STRENGTH_LEVEL = 3

# Default expire days for share link (since version 6.3.8)
# Once this value is configured, the user can no longer generate an share link with no expiration time.
# If the expiration value is not set when the share link is generated, the value configured here will be used.
SHARE_LINK_EXPIRE_DAYS_DEFAULT = 5

# minimum expire days for share link (since version 6.3.6)
# SHARE_LINK_EXPIRE_DAYS_MIN should be less than SHARE_LINK_EXPIRE_DAYS_DEFAULT (If the latter is set).
SHARE_LINK_EXPIRE_DAYS_MIN = 3 # default is 0, no limit.

# maximum expire days for share link (since version 6.3.6)
# SHARE_LINK_EXPIRE_DAYS_MIN should be greater than SHARE_LINK_EXPIRE_DAYS_DEFAULT (If the latter is set).
SHARE_LINK_EXPIRE_DAYS_MAX = 8 # default is 0, no limit.

# Default expire days for upload link (since version 7.1.6)
# Once this value is configured, the user can no longer generate an upload link with no expiration time.
# If the expiration value is not set when the upload link is generated, the value configured here will be used.
UPLOAD_LINK_EXPIRE_DAYS_DEFAULT = 5

# minimum expire days for upload link (since version 7.1.6)
# UPLOAD_LINK_EXPIRE_DAYS_MIN should be less than UPLOAD_LINK_EXPIRE_DAYS_DEFAULT (If the latter is set).
UPLOAD_LINK_EXPIRE_DAYS_MIN = 3 # default is 0, no limit.

# maximum expire days for upload link (since version 7.1.6)
# UPLOAD_LINK_EXPIRE_DAYS_MAX should be greater than UPLOAD_LINK_EXPIRE_DAYS_DEFAULT (If the latter is set).
UPLOAD_LINK_EXPIRE_DAYS_MAX = 8 # default is 0, no limit.

# force user login when view file/folder share link (since version 6.3.6)
SHARE_LINK_LOGIN_REQUIRED = False

# enable water mark when view(not edit) file in web browser (since version 6.3.6)
ENABLE_WATERMARK = False

# Disable sync with any folder. Default is `False`
# NOTE: since version 4.2.4
DISABLE_SYNC_WITH_ANY_FOLDER = False

# Enable or disable library history setting
ENABLE_REPO_HISTORY_SETTING = True

# Enable or disable normal user to create organization libraries
# Since version 5.0.5
ENABLE_USER_CREATE_ORG_REPO = True

# Enable or disable user share library to any group
# Since version 6.2.0
ENABLE_SHARE_TO_ALL_GROUPS = True

# Enable or disable user to clean trash (default is True)
# Since version 6.3.6
ENABLE_USER_CLEAN_TRASH = True

# Add a report abuse button on download links. (since version 7.1.0)
# Users can report abuse on the share link page, fill in the report type, contact information, and description.
# Default is false.
ENABLE_SHARE_LINK_REPORT_ABUSE = False

# Whether to use pdf.js to view pdf files online. Default is `True`, you can turn it off.
# NOTE: since version 1.4.
USE_PDFJS = True

# Online preview maximum file size, defaults to 30M.
FILE_PREVIEW_MAX_SIZE = 30 * 1024 * 1024

# Extensions of previewed text files.
# NOTE: since version 6.1.1
TEXT_PREVIEW_EXT = """ac, am, bat, c, cc, cmake, cpp, cs, css, diff, el, h, html,
htm, java, js, json, less, make, org, php, pl, properties, py, rb,
scala, script, sh, sql, txt, text, tex, vi, vim, xhtml, xml, log, csv,
groovy, rst, patch, go"""

# Enable or disable thumbnails
# NOTE: since version 4.0.2
ENABLE_THUMBNAIL = True

# Seafile only generates thumbnails for images smaller than the following size.
# Since version 6.3.8 pro, suport the psd online preview.
THUMBNAIL_IMAGE_SIZE_LIMIT = 30 # MB

# Absolute filesystem path to the directory that will hold thumbnail files.
THUMBNAIL_ROOT = '/shared/thumbnails/'

# Default size for picture preview. Enlarge this size can improve the preview quality.
# NOTE: since version 6.1.1
THUMBNAIL_SIZE_FOR_ORIGINAL = 1024

# Enable cloude mode and hide `Organization` tab.
CLOUD_MODE = True

# Disable global address book
ENABLE_GLOBAL_ADDRESSBOOK = False

# Enable authentication with ADFS
# Default is False
# Since 6.0.9
ENABLE_ADFS_LOGIN = False

# Enable authentication wit Kerberos
# Default is False
ENABLE_KRB5_LOGIN = False

# Enable authentication with Shibboleth
# Default is False
ENABLE_SHIBBOLETH_LOGIN = False

# This is outside URL for Seahub(Seafile Web).
# The domain part (i.e., www.example.com) will be used in generating share links and download/upload file via web.
# Note: Outside URL means "if you use Nginx, it should be the Nginx's address"
# Note: SERVICE_URL is moved to seahub_settings.py since 9.0.0
SERVICE_URL = 'https://seafile.{{SERVER_BASE_DOMAIN}}/'

# Fileserver URL
FILE_SERVER_ROOT = 'https://seafile.{{SERVER_BASE_DOMAIN}}/seafhttp'

# Disable settings via Web interface in system admin->settings
# Default is True
# Since 5.1.3
ENABLE_SETTINGS_VIA_WEB = False

# Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# If running in a Windows environment this must be set to the same as your
# system time zone.
TIME_ZONE = 'UTC'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
# Default language for sending emails.
LANGUAGE_CODE = 'en-gb'

# Custom language code choice.
LANGUAGES = (
    ('en-gb', 'English'),
)

# Set this to your website/company's name. This is contained in email notifications and welcome message when user login for the first time.
SITE_NAME = 'Seafile'

# Browser tab's title
SITE_TITLE = 'Seafile'

# If you don't want to run seahub website on your site's root path, set this option to your preferred path.
# e.g. setting it to '/seahub/' would run seahub on http://example.com/seahub/.
SITE_ROOT = '/'

# Max number of files when user upload file/folder.
# Since version 6.0.4
MAX_NUMBER_OF_FILES_FOR_FILEUPLOAD = 10000

# Control the language that send email. Default to user's current language.
# Since version 6.1.1
SHARE_LINK_EMAIL_LANGUAGE = 'en-gb'

# Interval for browser requests unread notifications
# Since PRO 6.1.4 or CE 6.1.2
UNREAD_NOTIFICATIONS_REQUEST_INTERVAL = 3 * 60 # seconds

# Whether to allow user to delete account, change login password or update basic user
# info on profile page.
# Since PRO 6.3.10
ENABLE_DELETE_ACCOUNT = False
ENABLE_UPDATE_USER_INFO = False
ENABLE_CHANGE_PASSWORD = False

# Get web api auth token on profile page.
ENABLE_GET_AUTH_TOKEN_BY_SESSION = True

# Since 8.0.6 CE/PRO version.
# Url redirected to after user logout Seafile.
# Usually configured as Single Logout url.
LOGOUT_REDIRECT_URL = 'https://seafile.{{SERVER_BASE_DOMAIN}}'

# Enable system admin add T&C, all users need to accept terms before using. Defaults to `False`.
# Since version 6.0
ENABLE_TERMS_AND_CONDITIONS = False

# Enable two factor authentication for accounts. Defaults to `False`.
# Since version 6.0
ENABLE_TWO_FACTOR_AUTH = False

# Enable user select a template when he/she creates library.
# When user select a template, Seafile will create folders releated to the pattern automaticly.
# Since version 6.0
LIBRARY_TEMPLATES = {
}

# Enable file comments. Default to `True`
# Since version 6.2.11
ENABLE_FILE_COMMENT = True

# If show contact email when search user.
ENABLE_SHOW_CONTACT_EMAIL_WHEN_SEARCH_USER = True

# Email settings
EMAIL_USE_TLS = True
EMAIL_HOST = "{{SMTP_HOST}}"
EMAIL_HOST_USER = "{{SMTP_USER}}"
EMAIL_HOST_PASSWORD = "{{SMTP_PASSWORD}}"
EMAIL_PORT = "{{SMTP_PORT}}"
DEFAULT_FROM_EMAIL = "noreply@{{SEVER_BASE_DOMAIN}}"
SERVER_EMAIL = "noreply@{{SEVER_BASE_DOMAIN}}"

# Replace default from email with user's email or not, defaults to ``False``
REPLACE_FROM_EMAIL = False

# Set reply-to header to user's email or not, defaults to ``False``. For details,
# please refer to http://www.w3.org/Protocols/rfc822/
ADD_REPLY_TO_HEADER = False

# OAUTH2 SSO settings
ENABLE_OAUTH = True

# If create new user when he/she logs in Seafile for the first time, defalut `True`.
OAUTH_CREATE_UNKNOWN_USER = True

# If active new user when he/she logs in Seafile for the first time, defalut `True`.
OAUTH_ACTIVATE_USER_AFTER_CREATION = True

# Usually OAuth works through SSL layer. If your server is not parametrized to allow HTTPS, some method will raise an "oauthlib.oauth2.rfc6749.errors.InsecureTransportError". Set this to `True` to avoid this error.
OAUTH_ENABLE_INSECURE_TRANSPORT = False

# Client id/secret generated by authorization server when you register your client application.
OAUTH_CLIENT_ID = "{{OAUTH_CLIENT_ID}}"
OAUTH_CLIENT_SECRET = "{{OAUTH_CLIENT_SECRET}}"

# Callback url when user authentication succeeded. Note, the redirect url you input when you register your client application MUST be exactly the same as this value.
OAUTH_REDIRECT_URL = 'https://seafile.{{SERVER_BASE_DOMAIN}}/oauth/callback/'

# The following should NOT be changed if you are using Github as OAuth provider.
OAUTH_PROVIDER_DOMAIN = 'idp.{{SERVER_BASE_DOMAIN}}'
OAUTH_AUTHORIZATION_URL = 'https://idp.{{SERVER_BASE_DOMAIN}}/realms/{{OAUTH_REALM_NAME}}/protocol/openid-connect/auth'
OAUTH_TOKEN_URL = 'https://idp.{{SERVER_BASE_DOMAIN}}/realms/{{OAUTH_REALM_NAME}}/protocol/openid-connect/token'
OAUTH_USER_INFO_URL = 'https://idp.{{SERVER_BASE_DOMAIN}}/realms/{{OAUTH_REALM_NAME}}/protocol/openid-connect/userinfo'
OAUTH_ATTRIBUTE_MAP = {
    "id": (True, "user_realm_id"),
    "name": (False, "name"),
    "email": (False, "email"),
}
