// you can set claims in the token
let username = user.getUsername()
let realmName = realm.getName()
token.setOtherClaims("userRealmId", username.concat("@", realmName));
