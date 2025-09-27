import Foundation

// MARK: - Diagnostics Domain Model

public struct DiagnosticsResult: Sendable {
    let systemInfo: SystemInfo
    let configuration: ConfigurationValidation
    let appConfiguration: AppConfigurationValidation
    let associatedDomains: AssociatedDomainsValidation
    let summary: Summary

    public struct ConfigurationValidation: Sendable {
        let mainHostScheme: HostSchemeValidation
        let mainHostname: HostnameValidation
        let additionalHosts: [AdditionalHostValidation]
        let clipboardWarning: Bool

        public struct HostSchemeValidation: Sendable {
            let isValid: Bool
            let scheme: String?
        }

        public struct HostnameValidation: Sendable {
            let isValid: Bool
            let hostname: String?
        }

        public struct AdditionalHostValidation: Sendable {
            let url: String
            let isValid: Bool
        }
    }

    public struct AppConfigurationValidation: Sendable {
        let appDelegate: AppDelegateValidation
        let urlScheme: URLSchemeValidation

        public struct AppDelegateValidation: Sendable {
            let hasDelegate: Bool
            let respondsToOpenURL: Bool
        }

        public struct URLSchemeValidation: Sendable {
            let expectedScheme: String
            let isFound: Bool
        }
    }

    public struct AssociatedDomainsValidation: Sendable {
        let hasEntitlements: Bool
        let mainDomain: DomainValidation?
        let additionalDomains: [DomainValidation]

        public struct DomainValidation: Sendable {
            let domain: String
            let isFound: Bool
        }
    }

    public struct Summary: Sendable {
        let errorCount: Int
        let warningCount: Int
        let isSimulator: Bool

        public var status: Status {
            if errorCount == 0 && warningCount == 0 {
                return .success
            } else if errorCount == 0 {
                return .warningsOnly
            } else {
                return .hasErrors
            }
        }

        public enum Status: Sendable {
            case success
            case warningsOnly
            case hasErrors
        }
    }
}
