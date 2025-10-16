---
title: "Configuring SAML and MFA on Cisco Firepower 1120"
date: 2025-08-12T00:00:00-08:00
draft: false
theme: default
menu:
  sidebar:
    name: "Cisco Firepower SAML/MFA"
    identifier: cisco-firepower-saml-mfa
    parent: networking
    weight: 310
description: "Lessons learned while setting up SAML authentication and MFA on a Cisco Firepower 1120 for VPN access."
tags: ["Cisco", "Firepower", "SAML", "MFA", "VPN", "ASDM"]
hero: images/site/custom-hero.jpg
---

## Overview

Recently, I configured SAML authentication with MFA on our Cisco Firepower 1120 to improve VPN security. This was part of our ongoing effort to standardize identity management across systems and ensure consistent MFA enforcement for all remote access.

## Reference Guides

These resources were critical in getting things working:

- [Cisco ASA AnyConnect VPN with Microsoft Entra ID (Cisco.com)](https://www.cisco.com/c/en/us/support/docs/security/anyconnect-secure-mobility-client/215935-configure-asa-anyconnect-vpn-with-micros.html)
- [Cisco Secure Firewall & Microsoft Entra SAML SSO Setup (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/saas-apps/cisco-secure-firewall-secure-client)
- [YouTube: SAML with AnyConnect](https://youtu.be/ORC0_0wsbQk?feature=shared)

## Lessons Learned

### 1. Redirect URL changes mean a new certificate

I initially downloaded the SAML certificate when setting up the configuration. Later, I found a typo in my redirect URL and corrected it.

What I missed was the nuance that **changing the redirect URL requires downloading a new SAML certificate** and importing it into the firewall. Without the updated cert, the SAML handshake failed.

### 2. CSRF cookie error

At one point I was getting a "CSRF cookie" error (I had even misspelled it in my notes). This turned out to be related to the SAML config not being fully applied after my changes.

### 3. Applying SAML profile changes in ASDM

It's not obvious in the official guides, but if you update the SAML profile, you should disable and re-enable it in ASDM to make sure the change takes effect:

1. Open the connection profile in ASDM
2. Set the SAML server to "None". Save and Apply
3. Re-select the SAML server. Save and Apply again

### Prerequisites

- Cisco Firepower 1120 with appropriate licensing
- Access to Firepower Device Manager (FDM) or Firepower Management Center (FMC)
- Identity Provider (IdP) configured (e.g., Azure AD, Okta, ADFS)
- Administrative privileges on both the Firepower device and IdP

## Configuration Steps

### Step 1: Prepare the Identity Provider

Before configuring the Firepower device, ensure your IdP is properly set up:

```text
1. Create a new SAML application in your IdP
2. Configure the following parameters:
   - Entity ID: https://<firepower-ip>/saml/metadata
   - ACS URL: https://<firepower-ip>/saml/acs
   - Name ID format: Email Address or Persistent
```

### Step 2: Access Firepower Management Interface

Connect to your Firepower 1120 management interface:

```bash
# Access via web browser
https://<firepower-management-ip>

# Or via SSH for CLI configuration
ssh admin@<firepower-management-ip>
```

### Step 3: Configure SAML Authentication

#### Via Firepower Device Manager (FDM)

1. Navigate to **Device** > **System Settings** > **Users**
2. Click **Identity Sources**
3. Select **Add SAML Identity Source**

Configure the following settings:

```text
Name: [Your IdP Name]
Entity ID: [IdP Entity ID from Step 1]
Sign-In URL: [IdP SSO URL]
Certificate: [Upload IdP signing certificate]
```

#### Via CLI Configuration

```bash
configure user identity-source saml
 name [IdP-Name]
 entity-id [IdP-Entity-ID]
 sign-in-url [IdP-SSO-URL]
 certificate [certificate-name]
exit
```

### Step 4: Configure Multi-Factor Authentication

Enable MFA policies for SAML users:

```text
1. Go to Authentication Policies
2. Create new policy for SAML users
3. Enable MFA requirement
4. Configure MFA methods (SMS, TOTP, etc.)
```

### Step 5: User Group Mapping

Map SAML groups to Firepower roles:

```bash
configure user identity-source saml group-mapping
 saml-group "Network-Admins" firepower-role "Admin"
 saml-group "Security-Team" firepower-role "Security Analyst"
exit
```

### Step 6: Testing Configuration

Test the SAML authentication:

1. Log out of the current session
2. Access the Firepower login page
3. Select "SAML Login" option
4. Verify redirection to IdP
5. Complete MFA challenge
6. Confirm successful login to Firepower

## Troubleshooting

### Common Issues

#### SAML Certificate Errors

```bash
# Verify certificate installation
show user identity-source saml certificate

# Check certificate expiration
show crypto ca certificates
```

#### Authentication Failures

```bash
# Check SAML logs
show logging | include SAML

# Verify time synchronization
show clock
```

#### MFA Not Triggering

- Verify MFA policy is applied to SAML users
- Check IdP MFA configuration
- Ensure user is in correct SAML group

### Useful Commands

```bash
# Show SAML configuration
show user identity-source saml

# Test SAML connectivity
test user identity-source saml [IdP-name]

# Monitor authentication attempts
show user login-history

# Clear SAML cache
clear user identity-source saml cache
```

## Security Considerations

- **Certificate Management**: Regularly update SAML certificates before expiration
- **Session Timeouts**: Configure appropriate session timeout values
- **Audit Logging**: Enable comprehensive logging for authentication events
- **Backup Configuration**: Maintain local admin accounts for emergency access

## Best Practices

1. **Regular Certificate Rotation**: Update SAML certificates annually
2. **Test Backup Access**: Ensure local admin accounts remain functional
3. **Monitor Failed Logins**: Set up alerts for authentication failures
4. **Document Configuration**: Keep detailed records of SAML settings
5. **Staged Deployment**: Test in lab environment before production

## Final Thoughts

MFA on VPNs isn't optional anymore — it's a must-have. This project reinforced that while vendor documentation is helpful, real-world implementation often involves nuances not covered in the official guides. The key lessons around certificate management and ASDM profile refreshing could save others significant troubleshooting time.

## References

**Primary Configuration Guides:**

- [Cisco ASA AnyConnect VPN with Microsoft Entra ID (Cisco.com)](https://www.cisco.com/c/en/us/support/docs/security/anyconnect-secure-mobility-client/215935-configure-asa-anyconnect-vpn-with-micros.html)
- [Cisco Secure Firewall & Microsoft Entra SAML SSO Setup (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/saas-apps/cisco-secure-firewall-secure-client)
- [YouTube: SAML with AnyConnect](https://youtu.be/ORC0_0wsbQk?feature=shared)

**Additional Resources:**

- [Cisco Firepower Management Center Configuration Guide](https://www.cisco.com/c/en/us/support/security/firepower-management-center/series.html)
- [SAML 2.0 Specification](https://docs.oasis-open.org/security/saml/v2.0/)
- [Cisco Identity Services Engine Integration](https://www.cisco.com/c/en/us/products/security/identity-services-engine/index.html)

---

*Last Updated: August 12, 2025*
*Tested on: Cisco Firepower 1120 running FTD 7.x*
