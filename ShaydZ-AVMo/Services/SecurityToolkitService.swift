import Foundation
import Combine
import CryptoKit

class SecurityToolkitService {
    // Singleton instance
    static let shared = SecurityToolkitService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var isProcessing = false
    @Published var error: String?
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    // MARK: - Password Analysis
    
    func analyzePasswordStrength(password: String) -> PasswordStrength {
        let length = password.count
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbols = password.rangeOfCharacter(from: .punctuationCharacters) != nil
        
        var score = 0
        var weaknesses: [String] = []
        var suggestions: [String] = []
        var timeToBreak = "Less than a second"
        
        // Length check
        if length < 8 {
            score += 10
            weaknesses.append("Password is too short")
            suggestions.append("Use at least 12 characters")
        } else if length < 12 {
            score += 25
            weaknesses.append("Password could be longer")
            suggestions.append("Use at least 12 characters")
        } else if length < 16 {
            score += 40
        } else {
            score += 50
        }
        
        // Character variety
        if !hasUppercase {
            weaknesses.append("No uppercase letters")
            suggestions.append("Add uppercase letters")
        } else {
            score += 10
        }
        
        if !hasLowercase {
            weaknesses.append("No lowercase letters")
            suggestions.append("Add lowercase letters")
        } else {
            score += 10
        }
        
        if !hasNumbers {
            weaknesses.append("No numbers")
            suggestions.append("Add numbers")
        } else {
            score += 10
        }
        
        if !hasSymbols {
            weaknesses.append("No special characters")
            suggestions.append("Add special characters like !@#$%^&*")
        } else {
            score += 20
        }
        
        // Check for common passwords
        let commonPasswords = ["password", "123456", "qwerty", "admin", "welcome", "password123"]
        if commonPasswords.contains(password.lowercased()) {
            score = 0
            weaknesses.append("This is a commonly used password")
            suggestions.append("Choose a completely different password")
        }
        
        // Check for sequential patterns
        let sequences = ["abcdefghijklmnopqrstuvwxyz", "0123456789", "qwertyuiop", "asdfghjkl", "zxcvbnm"]
        for sequence in sequences {
            for i in 0...(sequence.count - 3) {
                let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
                let endIndex = sequence.index(startIndex, offsetBy: 3)
                let pattern = String(sequence[startIndex..<endIndex])
                
                if password.lowercased().contains(pattern) {
                    weaknesses.append("Contains a sequential pattern (\(pattern))")
                    suggestions.append("Avoid sequential characters")
                    score = max(0, score - 10)
                    break
                }
            }
        }
        
        // Calculate time to break based on score
        if score < 20 {
            timeToBreak = "Less than a second"
        } else if score < 40 {
            timeToBreak = "A few minutes"
        } else if score < 60 {
            timeToBreak = "A few hours"
        } else if score < 80 {
            timeToBreak = "A few days"
        } else {
            timeToBreak = "Several years"
        }
        
        // Ensure score is within 0-100 range
        score = max(0, min(100, score))
        
        return PasswordStrength(
            score: score,
            timeToBreak: timeToBreak,
            weaknesses: weaknesses,
            suggestions: suggestions
        )
    }
    
    // MARK: - Hashing and Encryption
    
    func hashPassword(password: String, algorithm: HashAlgorithm) -> String {
        let passwordData = Data(password.utf8)
        
        switch algorithm {
        case .md5:
            let hashed = Insecure.MD5.hash(data: passwordData)
            return hashed.map { String(format: "%02hhx", $0) }.joined()
            
        case .sha1:
            let hashed = Insecure.SHA1.hash(data: passwordData)
            return hashed.map { String(format: "%02hhx", $0) }.joined()
            
        case .sha256:
            let hashed = SHA256.hash(data: passwordData)
            return hashed.map { String(format: "%02hhx", $0) }.joined()
            
        case .sha512:
            let hashed = SHA512.hash(data: passwordData)
            return hashed.map { String(format: "%02hhx", $0) }.joined()
            
        case .bcrypt:
            // In a real implementation, we'd use a proper bcrypt library
            // For this demo, we'll simulate it
            return "$2a$12$" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
            
        case .argon2:
            // In a real implementation, we'd use a proper argon2 library
            // For this demo, we'll simulate it
            return "$argon2id$v=19$m=65536,t=3,p=4$" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    }
    
    func encryptData(data: Data, password: String) -> EncryptedData? {
        do {
            // Generate a symmetric key from the password
            let passwordData = Data(password.utf8)
            let hashedPassword = SHA256.hash(data: passwordData)
            let key = SymmetricKey(data: hashedPassword)
            
            // Generate a random initialization vector
            var iv = Data(count: 16)
            _ = iv.withUnsafeMutableBytes { pointer in
                SecRandomCopyBytes(kSecRandomDefault, 16, pointer.baseAddress!)
            }
            
            // Encrypt the data using AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: AES.GCM.Nonce(data: iv))
            
            guard let encrypted = sealedBox.combined else {
                return nil
            }
            
            return EncryptedData(data: encrypted, iv: iv, algorithm: "AES-GCM-256")
        } catch {
            return nil
        }
    }
    
    func decryptData(encryptedData: EncryptedData, password: String) -> Data? {
        do {
            // Generate the same symmetric key from the password
            let passwordData = Data(password.utf8)
            let hashedPassword = SHA256.hash(data: passwordData)
            let key = SymmetricKey(data: hashedPassword)
            
            // Create a sealed box from the encrypted data
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData.data)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            return nil
        }
    }
    
    // MARK: - Social Engineering Tools
    
    func generatePhishingTemplate(type: String) -> PhishingCampaign {
        // In a real implementation, we would have templates for different types
        // For this demo, we'll simulate generating a template
        
        var template = ""
        var targetProfile = ""
        var successLikelihood = 0.0
        var indicators: [String] = []
        
        switch type.lowercased() {
        case "banking":
            template = """
            URGENT: Your account has been temporarily limited
            
            Dear valued customer,
            
            We have detected suspicious activity on your account. Your account access has been limited for your security.
            
            Please verify your identity by clicking the link below:
            [MALICIOUS LINK]
            
            If you don't verify within 24 hours, your account will be permanently restricted.
            
            Security Department
            [BANK NAME]
            """
            targetProfile = "Banking customers, general public"
            successLikelihood = 0.65
            indicators = [
                "Urgency tactics",
                "Generic greeting",
                "Threat of account restriction",
                "Request for immediate action",
                "Suspicious link"
            ]
            
        case "corporate":
            template = """
            Subject: Important: Action Required - Update your company credentials
            
            Hi Team Member,
            
            IT Security has implemented a new secure sign-in system.
            
            You must update your credentials by end of day to maintain access to company resources.
            
            Update now: [MALICIOUS LINK]
            
            Best regards,
            IT Security Team
            [COMPANY]
            """
            targetProfile = "Corporate employees"
            successLikelihood = 0.55
            indicators = [
                "Generic greeting",
                "Spoofed internal department",
                "Imposed deadline",
                "Suspicious link"
            ]
            
        case "covid":
            template = """
            Subject: COVID-19 Vaccination Appointment Confirmation
            
            Important COVID-19 Vaccination Update
            
            Your vaccination appointment has been scheduled. Please review and confirm your details by clicking below:
            
            [MALICIOUS LINK]
            
            This appointment will be cancelled if not confirmed within 48 hours.
            
            Department of Health
            """
            targetProfile = "General public during pandemic"
            successLikelihood = 0.75
            indicators = [
                "Exploits current events",
                "Health authority impersonation",
                "Urgency tactics",
                "Suspicious link"
            ]
            
        default:
            template = """
            Subject: You've received a new document
            
            Hi there,
            
            You have received an important document. Click below to view it:
            
            [MALICIOUS LINK]
            
            The document will expire in 24 hours.
            
            Regards,
            Document Sharing Service
            """
            targetProfile = "General office workers"
            successLikelihood = 0.45
            indicators = [
                "Generic greeting",
                "Vague content",
                "Time pressure",
                "Suspicious link"
            ]
        }
        
        return PhishingCampaign(
            template: template,
            targetProfile: targetProfile,
            successLikelihood: successLikelihood,
            indicators: indicators
        )
    }
    
    func analyzePhishingAttempt(email: String) -> PhishingIndicators {
        // In a real implementation, we would analyze the actual email
        // For this demo, we'll do a simple analysis based on common patterns
        
        var suspiciousElements: [PhishingIndicators.SuspiciousElement] = []
        var riskScore = 0
        
        // Check for urgency language
        let urgencyPhrases = ["urgent", "immediate", "alert", "warning", "important", "attention", "now", "critical", "limited time", "expire"]
        for phrase in urgencyPhrases {
            if email.lowercased().contains(phrase) {
                suspiciousElements.append(
                    PhishingIndicators.SuspiciousElement(
                        type: .urgencyTactics,
                        description: "Creates false sense of urgency",
                        location: "Email body"
                    )
                )
                riskScore += 15
                break
            }
        }
        
        // Check for suspicious links
        let suspiciousLinkPatterns = ["click here", "login", "verify", "confirm", "account", "update", "www", "http"]
        for pattern in suspiciousLinkPatterns {
            if email.lowercased().contains(pattern) {
                suspiciousElements.append(
                    PhishingIndicators.SuspiciousElement(
                        type: .maliciousLink,
                        description: "Contains suspicious link or call to action",
                        location: "Email body"
                    )
                )
                riskScore += 20
                break
            }
        }
        
        // Check for grammatical errors
        let grammaticalErrors = ["you're account", "there system", "we seen", "been compromise", "kindly", "dear customer"]
        for error in grammaticalErrors {
            if email.lowercased().contains(error) {
                suspiciousElements.append(
                    PhishingIndicators.SuspiciousElement(
                        type: .grammaticalErrors,
                        description: "Contains grammatical errors",
                        location: "Throughout email"
                    )
                )
                riskScore += 10
                break
            }
        }
        
        // Check for spoofed sender
        let spoofedSenders = ["support@", "security@", "admin@", "service@", "team@", "no-reply@"]
        for sender in spoofedSenders {
            if email.lowercased().contains(sender) {
                suspiciousElements.append(
                    PhishingIndicators.SuspiciousElement(
                        type: .spoofedSender,
                        description: "Potentially spoofed sender email",
                        location: "Sender address"
                    )
                )
                riskScore += 15
                break
            }
        }
        
        // Check for attachments
        let attachmentIndicators = ["attach", ".doc", ".pdf", ".zip", ".exe", "file"]
        for indicator in attachmentIndicators {
            if email.lowercased().contains(indicator) {
                suspiciousElements.append(
                    PhishingIndicators.SuspiciousElement(
                        type: .attachments,
                        description: "Contains suspicious attachment",
                        location: "Attachments"
                    )
                )
                riskScore += 25
                break
            }
        }
        
        // Determine recommendation based on risk score
        var recommendation = ""
        if riskScore >= 60 {
            recommendation = "High probability phishing attempt. Do not interact with this email and report to security team."
        } else if riskScore >= 30 {
            recommendation = "Suspicious email with multiple phishing indicators. Verify with sender through another communication channel before taking any action."
        } else {
            recommendation = "Low risk, but still exercise caution. When in doubt, verify through official channels."
        }
        
        // Ensure score is within 0-100 range
        riskScore = max(0, min(100, riskScore))
        
        return PhishingIndicators(
            suspiciousElements: suspiciousElements,
            riskScore: riskScore,
            recommendation: recommendation
        )
    }
}
