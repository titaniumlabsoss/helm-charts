# Security Release Process

The Titanium Labs Helm Charts project has adopted this security disclosure and response policy to ensure we responsibly handle critical issues in our Helm charts and Kubernetes deployment configurations.

## Supported Versions

Currently supported chart versions:
- Latest stable releases (semantic versioning)
- Current major/minor versions (e.g., `1.2.x`)
- Charts released within the last 12 months

## Reporting a Vulnerability - Private Disclosure Process

Security is of the highest importance and all security vulnerabilities or suspected security vulnerabilities should be reported to this project privately, to minimize attacks against current users before they are fixed. Vulnerabilities will be investigated and patched on the next patch (or minor) release as soon as possible. This information could be kept entirely internal to the project.

If you know of a publicly disclosed security vulnerability for this project, please **IMMEDIATELY** contact the maintainers of this project privately. The use of encrypted email is encouraged.

**IMPORTANT: Do not file public issues on GitHub for security vulnerabilities**

To report a vulnerability or a security-related issue, please contact the maintainers with enough details through one of the following channels:

* **Email**: `security@titaniumlabs.io` (preferred method)
* **GitHub Security Advisory**: Open a [GitHub Security Advisory](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability). This allows for anyone to report security vulnerabilities directly and privately to the maintainers via GitHub.

The report will be fielded by the Titanium Labs security team who have committer and release permissions. Feedback will be sent within 3 business days, including a detailed plan to investigate the issue and any potential workarounds to perform in the meantime.

Do not report non-security-impacting bugs through this channel. Use [GitHub issues](https://github.com/titaniumlabsoss/helm-charts/issues) for all non-security-impacting bugs.

## Proposed Report Content

Provide a descriptive title and in the description of the report include the following information:

* Basic identity information, such as your name and your affiliation or company.
* Detailed steps to reproduce the vulnerability (helm commands, Kubernetes manifests, chart values, and logs are all helpful to us).
* Description of the effects of the vulnerability on our Helm charts and the related Kubernetes deployments, so that the maintainers can reproduce it.
* How the vulnerability affects chart usage and an estimation of the attack surface, if there is one.
* List other projects, charts, or dependencies that were used in conjunction with our charts to produce the vulnerability.
* Affected chart names and versions (e.g., `titaniumlabs/postgres:1.2.3`, `titaniumlabs/nginx:2.1.0`).
* Kubernetes environment details (Kubernetes version, Helm version, cluster configuration, etc.).

## When to report a vulnerability

* When you think our Helm charts have a potential security vulnerability.
* When you suspect a potential vulnerability but you are unsure that it impacts our charts.
* When you know of or suspect a potential vulnerability in upstream charts or dependencies that affects our Helm charts.
* When you discover issues with our security configurations that could lead to security weaknesses.
* When you find discrepancies between our security claims and actual chart behavior.
* When you find insecure default values or configurations in our charts.

## Patch, Release, and Disclosure

The Titanium Labs security team will respond to vulnerability reports as follows:

1. The security team will investigate the vulnerability and determine its effects and criticality.
2. If the issue is not deemed to be a vulnerability, the team will follow up with a detailed reason for rejection.
3. The security team will initiate a conversation with the reporter within 3 business days.
4. If a vulnerability is acknowledged and the timeline for a fix is determined, the team will work on a plan to communicate with the appropriate community, including identifying mitigating steps that affected users can take to protect themselves until the fix is rolled out.
5. The security team will also create a [Security Advisory](https://docs.github.com/en/code-security/repository-security-advisories/publishing-a-repository-security-advisory) using the [CVSS Calculator](https://www.first.org/cvss/calculator/3.0), if it is not created yet. The team makes the final call on the calculated CVSS; it is better to move quickly than making the CVSS perfect. Issues may also be reported to [Mitre](https://cve.mitre.org/) using this [scoring calculator](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator). The draft advisory will initially be set to private.
6. The security team will work on fixing the vulnerability and perform internal testing before preparing to roll out the fix.
7. Once the fix is confirmed, the team will patch the vulnerability in the next patch or minor release, and backport a patch release into all earlier supported releases.
8. New chart versions will be built and published to the Helm repository with updated versions.

## Public Disclosure Process

The security team publishes the public advisory to this project's community via GitHub. In most cases, additional communication via Slack, Twitter, mailing lists, blog, and other channels will assist in educating the project's users and rolling out the patched release to affected users.

The security team will also publish any mitigating steps users can take until the fix can be applied to their Kubernetes deployments. This project's distributors will handle creating and publishing their own security advisories.

## Kubernetes-Specific Security Considerations

When evaluating security issues in our Helm charts, we consider the following attack vectors:

* **RBAC privilege escalation** - Overly permissive role-based access controls
* **Network policy bypasses** - Misconfigurations allowing unauthorized network access
* **Pod security violations** - Containers running with unnecessary privileges
* **Secret management issues** - Insecure handling of sensitive data in charts
* **Supply chain attacks** - Compromised dependencies or upstream charts
* **Configuration vulnerabilities** - Insecure default values or missing security controls
* **Resource exhaustion** - Missing resource limits leading to DoS conditions

## Confidentiality, Integrity and Availability

We consider vulnerabilities leading to the compromise of data confidentiality, elevation of privilege, or integrity to be our highest priority concerns. Availability, in particular in areas relating to DoS and resource exhaustion, is also a serious security concern. The security team takes all vulnerabilities, potential vulnerabilities, and suspected vulnerabilities seriously and will investigate them in an urgent and expeditious manner.

Note that while our charts are configured according to industry standards (CIS Benchmarks, DISA STIGs, NIST guidelines), the security of deployed applications also depends on proper cluster configuration and ongoing maintenance. We recommend following Kubernetes security best practices including:

* Enabling Pod Security Standards in your cluster
* Implementing network policies for traffic segmentation
* Running containers as non-root users with read-only filesystems
* Using external secret management solutions
* Regular chart updates and security scanning
* Proper RBAC configuration with least privilege principles

We will not act on any security disclosure that relates purely to misconfigurations in user deployments that don't follow documented security best practices. However, if our documentation is unclear or our defaults could be improved, we welcome feedback through our regular issue process.

## Security Scanning and Monitoring

Our charts undergo continuous security validation using:

* **Helm lint** - Chart validation and best practice checks
* **Kubesec** - Kubernetes manifest security analysis
* **Checkov** - Infrastructure-as-code security scanning
* **Chart signing** - Provenance and integrity verification
* **RBAC analysis** - Privilege escalation detection
* **Network policy validation** - Traffic flow security verification
