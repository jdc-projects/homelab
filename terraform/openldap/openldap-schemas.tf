resource "kubernetes_config_map" "openldap_custom_schemas" {
  metadata {
    name      = "openldap-custom-schemas"
    namespace = kubernetes_namespace.openldap.metadata[0].name
  }

  data = {
    "00-memberof.ldif"   = <<-EOF
      dn: cn=module,cn=config
      cn: module
      objectClass: olcModuleList
      olcModulePath: /opt/bitnami/openldap/lib/openldap
      olcModuleLoad: memberof.so
      olcModuleLoad: refint.so

      dn: olcOverlay=memberof,olcDatabase={2}mdb,cn=config
      objectClass: olcMemberOf
      objectClass: olcOverlayConfig
      olcOverlay: memberof
      olcMemberOfRefInt: TRUE
      olcMemberOfGroupOC: groupOfNames
      olcMemberOfMemberAD: member
      olcMemberOfMemberOfAD: memberOf

      dn: olcOverlay=refint,olcDatabase={2}mdb,cn=config
      objectClass: olcConfig
      objectClass: olcOverlayConfig
      objectClass: olcRefintConfig
      objectClass: top
      olcOverlay: refint
      olcRefintAttribute: memberof member manager owner
    EOF
    "10-rfc2307bis.ldif" = <<-EOF
      # source:
      # https://github.com/cajus/gosa-gui/blob/master/contrib/openldap/rfc2307bis.ldif
      dn: cn=rfc2307bis,cn=schema,cn=config
      objectClass: olcSchemaConfig
      cn: rfc2307bis
      olcAttributeTypes: (
        1.3.6.1.1.1.1.2
        NAME 'gecos'
        DESC 'The GECOS field; the common name'
        EQUALITY caseIgnoreIA5Match
        SUBSTR caseIgnoreIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.3
        NAME 'homeDirectory'
        DESC 'The absolute path to the home directory'
        EQUALITY caseExactIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.4
        NAME 'loginShell'
        DESC 'The path to the login shell'
        EQUALITY caseExactIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.5
        NAME 'shadowLastChange'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.6
        NAME 'shadowMin'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.7
        NAME 'shadowMax'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.8
        NAME 'shadowWarning'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.9
        NAME 'shadowInactive'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.10
        NAME 'shadowExpire'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.11
        NAME 'shadowFlag'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.12
        NAME 'memberUid'
        EQUALITY caseExactIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.13
        NAME 'memberNisNetgroup'
        EQUALITY caseExactIA5Match
        SUBSTR caseExactIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.14
        NAME 'nisNetgroupTriple'
        DESC 'Netgroup triple'
        EQUALITY caseIgnoreIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.15
        NAME 'ipServicePort'
        DESC 'Service port number'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.16
        NAME 'ipServiceProtocol'
        DESC 'Service protocol name'
        SUP name
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.17
        NAME 'ipProtocolNumber'
        DESC 'IP protocol number'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.18
        NAME 'oncRpcNumber'
        DESC 'ONC RPC number'
        EQUALITY integerMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.27
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.19
        NAME 'ipHostNumber'
        DESC 'IPv4 addresses as a dotted decimal omitting leading zeros or IPv6 addresses as defined in RFC2373'
        SUP name
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.20
        NAME 'ipNetworkNumber'
        DESC 'IP network as a dotted decimal, eg. 192.168, omitting leading zeros'
        SUP name
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.21
        NAME 'ipNetmaskNumber'
        DESC 'IP netmask as a dotted decimal, eg. 255.255.255.0, omitting leading zeros'
        EQUALITY caseIgnoreIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.22
        NAME 'macAddress'
        DESC 'MAC address in maximal, colon separated hex notation, eg. 00:00:92:90:ee:e2'
        EQUALITY caseIgnoreIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.23
        NAME 'bootParameter'
        DESC 'rpc.bootparamd parameter'
        EQUALITY caseExactIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.24
        NAME 'bootFile'
        DESC 'Boot image name'
        EQUALITY caseExactIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.26
        NAME 'nisMapName'
        DESC 'Name of a A generic NIS map'
        SUP name
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.27
        NAME 'nisMapEntry'
        DESC 'A generic NIS entry'
        EQUALITY caseExactIA5Match
        SUBSTR caseExactIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.28
        NAME 'nisPublicKey'
        DESC 'NIS public key'
        EQUALITY octetStringMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.40
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.29
        NAME 'nisSecretKey'
        DESC 'NIS secret key'
        EQUALITY octetStringMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.40
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.30
        NAME 'nisDomain'
        DESC 'NIS domain'
        EQUALITY caseIgnoreIA5Match
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.31
        NAME 'automountMapName'
        DESC 'automount Map Name'
        EQUALITY caseExactIA5Match
        SUBSTR caseExactIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.32
        NAME 'automountKey'
        DESC 'Automount Key value'
        EQUALITY caseExactIA5Match
        SUBSTR caseExactIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcAttributeTypes: (
        1.3.6.1.1.1.1.33
        NAME 'automountInformation'
        DESC 'Automount information'
        EQUALITY caseExactIA5Match
        SUBSTR caseExactIA5SubstringsMatch
        SYNTAX 1.3.6.1.4.1.1466.115.121.1.26
        SINGLE-VALUE
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.0
        NAME 'posixAccount'
        DESC 'Abstraction of an account with POSIX attributes'
        SUP top
        AUXILIARY
        MUST ( cn $ uid $ uidNumber $ gidNumber $ homeDirectory )
        MAY ( userPassword $ loginShell $ gecos $ description )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.1
        NAME 'shadowAccount'
        DESC 'Additional attributes for shadow passwords'
        SUP top
        AUXILIARY
        MUST uid
        MAY ( userPassword $ description $ shadowLastChange $ shadowMin $ shadowMax $ shadowWarning $ shadowInactive $ shadowExpire $ shadowFlag )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.2
        NAME 'posixGroup'
        DESC 'Abstraction of a group of accounts'
        SUP top
        AUXILIARY
        MUST gidNumber
        MAY ( userPassword $ memberUid $ description )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.3
        NAME 'ipService'
        DESC 'Abstraction an Internet Protocol service. Maps an IP port and protocol (such as tcp or udp) to one or more names; the distinguished value of the cn attribute denotes the services canonical name'
        SUP top
        STRUCTURAL
        MUST ( cn $ ipServicePort $ ipServiceProtocol )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.4
        NAME 'ipProtocol'
        DESC 'Abstraction of an IP protocol. Maps a protocol number to one or more names. The distinguished value of the cn attribute denotes the protocols canonical name'
        SUP top
        STRUCTURAL
        MUST ( cn $ ipProtocolNumber )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.5
        NAME 'oncRpc'
        DESC 'Abstraction of an Open Network Computing (ONC) [RFC1057] Remote Procedure Call (RPC) binding. This class maps an ONC RPC number to a name. The distinguished value of the cn attribute denotes the RPC services canonical name'
        SUP top
        STRUCTURAL
        MUST ( cn $ oncRpcNumber )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.6
        NAME 'ipHost'
        DESC 'Abstraction of a host, an IP device. The distinguished value of the cn attribute denotes the hosts canonical name. Device SHOULD be used as a structural class'
        SUP top
        AUXILIARY
        MUST ( cn $ ipHostNumber )
        MAY ( userPassword $ l $ description $ manager )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.7
        NAME 'ipNetwork'
        DESC 'Abstraction of a network. The distinguished value of the cn attribute denotes the networks canonical name'
        SUP top
        STRUCTURAL
        MUST ipNetworkNumber
        MAY ( cn $ ipNetmaskNumber $ l $ description $ manager )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.8
        NAME 'nisNetgroup'
        DESC 'Abstraction of a netgroup. May refer to other netgroups'
        SUP top
        STRUCTURAL
        MUST cn
        MAY ( nisNetgroupTriple $ memberNisNetgroup $ description )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.9
        NAME 'nisMap'
        DESC 'A generic abstraction of a NIS map'
        SUP top
        STRUCTURAL
        MUST nisMapName
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.10
        NAME 'nisObject'
        DESC 'An entry in a NIS map'
        SUP top
        STRUCTURAL
        MUST ( cn $ nisMapEntry $ nisMapName )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.11
        NAME 'ieee802Device'
        DESC 'A device with a MAC address; device SHOULD be used as a structural class'
        SUP top
        AUXILIARY
        MAY macAddress
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.12
        NAME 'bootableDevice'
        DESC 'A device with boot parameters; device SHOULD be used as a structural class'
        SUP top
        AUXILIARY
        MAY ( bootFile $ bootParameter )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.14
        NAME 'nisKeyObject'
        DESC 'An object with a public and secret key'
        SUP top
        AUXILIARY
        MUST ( cn $ nisPublicKey $ nisSecretKey )
        MAY ( uidNumber $ description )
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.15
        NAME 'nisDomainObject'
        DESC 'Associates a NIS domain with a naming context'
        SUP top
        AUXILIARY
        MUST nisDomain
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.16
        NAME 'automountMap'
        SUP top
        STRUCTURAL
        MUST ( automountMapName )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.1.1.2.17
        NAME 'automount'
        DESC 'Automount information'
        SUP top
        STRUCTURAL
        MUST ( automountKey $ automountInformation )
        MAY description
        )
      olcObjectClasses: (
        1.3.6.1.4.1.5322.13.1.1
        NAME 'namedObject'
        SUP top
        STRUCTURAL
        MAY cn
        )
    EOF
  }
}
