// you can set claims in the token
var username = user.getUsername()
var realmName = realm.getName()
token.setOtherClaims("user_realm_id", username.concat("@", realmName));
