/**
 * Merge with concatenation for the values of attributes obtained
 * from the token with the attributes obtained from the roles. If for
 * example a group and a role have the same attribute key, the values
 * for that key from the group and role will be concatenated.
 *
 * Known limitations:
 * When only roles have a certain attribute, and not a group, the
 * mapper only uses the first role it can find. Bug was difficult to
 * fix because state in the variable currentClaims seems to be
 * persisted over multiple calls.
 * Workaround: Also add this specific attribute to a group with a
 * dummy value.
 *
 * NOTE: there is no role attribute mapper out-of-the-box in
 * Keycloak.
 *
 * Available variables in script:
 * user - the current user
 * realm - the current realm
 * token - the current token
 * userSession - the current userSession
 * keycloakSession - the current keycloakSession
 *
 * Documentation on available variables:
 * https://stackoverflow.com/a/52984849
 */

var currentClaims = {};
token.getOtherClaims().forEach(function(k, v) {
  currentClaims[k] = v;
});

function isMultiValued(v) {
  // From experience, multivalued attribute values are sometimes
  // Arrays and sometimes Objects. Thus look for negative case:
  // anything other than a string is multivalued.
  return !(typeof v === 'string' || v instanceof String);
}

function addToList(l, values) {
  for each(var v in values) {
    l.add(v);
  }
  return l;
}

function toStringArray(arr) {
  return Java.to(arr, "java.lang.String[]");
}

user.getRealmRoleMappings().forEach(function(roleModel) {
  roleModel.getAttributes().forEach(function(k, v) {
    var currentValue = currentClaims[k];
    if (k in currentClaims) {
      if (!isMultiValued(currentValue)) {
        v = toStringArray([currentValue].concat(v));
      } else {
        v = addToList(currentValue, v);
      }
    }
    currentClaims[k] = v; // <= to also aggregate over roles!
    token.setOtherClaims(k, v);
  });
});
