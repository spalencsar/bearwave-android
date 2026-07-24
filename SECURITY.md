# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability within BearWave Android, please send an email to the project maintainer via GitHub.

Please include the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- Initial response: within 48 hours
- Assessment: within 1 week
- Fix deployment: depends on severity

## Scope

This security policy applies to:

- The BearWave Android Flutter application
- API communications with radio-browser.info
- Station-homepage and artwork discovery
- Background audio and Android Auto MediaBrowserService behavior
- Google Cast discovery and Cast session control
- Local data storage (SharedPreferences)

## Best Practices

- The app does not collect or transmit personal data
- Radio Browser API communication and dynamically discovered API-node requests
  use HTTPS; discovered node names are restricted to
  `*.api.radio-browser.info`
- Internet radio streams and station homepages may use HTTP when supplied that
  way by Radio Browser or the user
- Homepage artwork discovery bounds response sizes, timeouts, redirects, and
  concurrency, and rejects redirects to literal local/private addresses
- Cast device discovery stays on the local network
- No secrets or API keys are hardcoded
- Local storage is limited to SharedPreferences data such as settings,
  favorites, history, playback state, and the last-known-good country list
