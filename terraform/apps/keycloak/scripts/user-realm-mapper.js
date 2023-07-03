// you can set claims in the token
var username = user.getUsername()
var realmName = realm.getName()
token.setOtherClaims("userRealmId", username.concat("@", realmName));
