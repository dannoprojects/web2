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
description: "Step-by-step guide for setting up Azure AD SAML authentication with MFA for Cisco Firepower VPN access, including the CLI commands missing from Microsoft's documentation."
tags: ["Cisco", "Firepower", "SAML", "MFA", "VPN", "ASDM", "Azure AD", "Entra ID"]
hero: images/site/custom-hero.jpg
---

## Overview

Setting up SAML authentication with MFA on a Cisco Firepower 1120 for VPN access is essential for modern security requirements. Microsoft's documentation provides a good starting point, but it's missing critical CLI configuration commands for the Firepower side.

This guide fills in those gaps and documents the lessons learned during implementation.

## Prerequisites

- Cisco Firepower 1120 with appropriate licensing and AnyConnect
- Azure AD (Microsoft Entra ID) tenant with administrative access
- Access to Firepower via ASDM or CLI
- Your Firepower VPN's public FQDN and SSL certificate configured

## Configuration Steps

### Step 1: Create the Enterprise Application in Azure

Follow Microsoft's guide to create the Cisco Secure Firewall app in Azure AD:

1. Sign in to the [Azure portal](https://portal.azure.com/)
2. Navigate to **Microsoft Entra ID** > **Enterprise Applications**
3. Click **New application** > **Create your own application**
4. Search for "Cisco Secure Firewall - Secure Client (Clientless VPN)" and add it
5. Navigate to **Single sign-on** and select **SAML**

### Step 2: Configure SAML Settings in Azure

Configure the basic SAML settings:

```text
Identifier (Entity ID): https://[your-vpn-fqdn.domain.com]
Reply URL (ACS): https://[your-vpn-fqdn.domain.com]/saml/acs
Sign on URL: https://[your-vpn-fqdn.domain.com]
```

**Important:** These URLs must exactly match your Firepower's base URL configuration.

### Step 3: Download the SAML Certificate

1. In the Azure SAML configuration, scroll to **SAML Signing Certificate**
2. Download the **Certificate (Base64)**
3. Open the certificate file in a text editor - you'll need this content for the CLI configuration

### Step 4: Note Your Azure Tenant ID

You'll need your Azure Tenant ID for the Firepower configuration:

1. Navigate to **Microsoft Entra ID** > **Overview**
2. Copy your **Tenant ID** (it looks like: `12345678-1234-1234-1234-123456789abc`)

### Step 5: Configure Firepower SAML (The Missing Piece)

Here's the commands in one place with tabs and formatting for easy copy-paste. Edit the placeholders as needed.

```bash
config t
crypto ca trustpoint [YourTrustpointName]
  revocation-check none
  no id-usage
  enrollment terminal
  no ca-check
crypto ca authenticate [YourTrustpointName]
-----BEGIN CERTIFICATE-----
[Paste Base64 certificate from Azure here]
-----END CERTIFICATE-----
quit
webvpn
  saml idp https://sts.windows.net/[AZURE-TENANT-ID]/
    url sign-in https://login.microsoftonline.com/[AZURE-TENANT-ID]/saml2
    url sign-out https://login.microsoftonline.com/common/wsfederation?wa=wsignout1.0
    trustpoint idp [YourTrustpointName]
    trustpoint sp [YourFirewallSSLCertName]
    no force re-authentication
    no signature
    base-url https://[your-vpn-fqdn.domain.com]
end
write mem
```

**Configuration parameters:**
- `[YourTrustpointName]` - A descriptive name for the Azure AD certificate (e.g., "AzureAD-SAML")
- `[AZURE-TENANT-ID]` - Your Azure tenant ID from Step 4
- `[YourFirewallSSLCertName]` - The existing SSL certificate trustpoint name on your Firepower
- `[your-vpn-fqdn.domain.com]` - Your VPN's public FQDN (must match Azure configuration)

### Step 6: Configure the Connection Profile in ASDM

1. Open ASDM and navigate to **Remote Access VPN** > **Network (Client) Access** > **AnyConnect Connection Profiles**
2. Create the connection profile using the endpoints from Azure.
3. Assign a group policy.
4. Click **OK** and **Apply**

## Lessons Learned

### 1. Redirect URL changes mean a new certificate

I initially downloaded the SAML certificate when setting up the configuration. Later, I found a typo in my redirect URL and corrected it in Azure.

**Critical lesson:** Changing the redirect URL in Azure requires downloading a new SAML certificate and re-importing it into the Firepower. The certificate is tied to the specific URLs configured in Azure. Without the updated cert, the SAML handshake will fail with cryptic errors.

### 2. Applying SAML profile changes in ASDM

The official guides don't emphasize this, but if you update the SAML profile, you should disable and re-enable it in ASDM:

1. Open the connection profile in ASDM
2. Set the SAML server to "None". Save and Apply
3. Re-select the SAML server. Save and Apply again

This ensures the changes fully take effect on the running configuration.

### 3. Base URL must be exact

The `base-url` in your Firepower configuration must exactly match the URLs configured in Azure (Identifier, Reply URL, Sign-on URL). Any mismatch will cause authentication failures.

## Testing the Configuration

1. Clear your browser cache or use an incognito window
2. Navigate to your VPN URL: `https://[your-vpn-fqdn.domain.com]`
3. You should be redirected to the Azure AD login page
4. After authenticating with Azure AD (and completing MFA), you should be redirected back to the VPN portal
5. AnyConnect should download and connect automatically

## Troubleshooting

### SAML Authentication Fails

```bash
# Check SAML configuration
show webvpn saml idp

# Verify certificate is installed
show crypto ca certificates
```

### Certificate Errors

If you see certificate validation errors, verify:
- The certificate was copied correctly (including BEGIN/END lines)
- No extra spaces or line breaks were introduced
- The certificate matches the current Azure configuration

### Redirect Loop or CSRF Errors

This typically indicates:
- Mismatch between Azure URLs and Firepower base-url
- SAML profile not properly applied (see Lesson #2)
- Certificate doesn't match the current Azure configuration (see Lesson #1)

### Useful Commands

```bash
# Show SAML IDP configuration
show run webvpn

# Test certificate
show crypto ca certificates [YourTrustpointName]

# Check WebVPN sessions
show vpn-sessiondb anyconnect

# Debug SAML (use with caution)
debug webvpn saml 255
```

## Conclusion

The Microsoft documentation provides a good foundation, but the actual CLI configuration for Firepower is the critical missing piece. With SAML and Azure AD MFA properly configured, you have a secure, modern authentication method for your VPN that meets current security standards.

## References

**Primary Configuration Guides:**

- [Cisco Secure Firewall & Microsoft Entra SAML SSO Setup (Microsoft Learn)](https://learn.microsoft.com/en-us/entra/identity/saas-apps/cisco-secure-firewall-secure-client) - The starting point, but incomplete
- [Cisco ASA AnyConnect VPN with Microsoft Entra ID (Cisco.com)](https://www.cisco.com/c/en/us/support/docs/security/anyconnect-secure-mobility-client/215935-configure-asa-anyconnect-vpn-with-micros.html)
- [YouTube: SAML with AnyConnect](https://youtu.be/ORC0_0wsbQk?feature=shared)

**Additional Resources:**

- [Cisco ASA CLI Configuration Guide](https://www.cisco.com/c/en/us/support/security/asa-5500-series-next-generation-firewalls/products-installation-and-configuration-guides-list.html)
- [Microsoft Entra ID Documentation](https://learn.microsoft.com/en-us/entra/identity/)
