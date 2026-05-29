import Foundation
import CryptoKit

/// Генерация пары ключей WireGuard (Curve25519). Приватный ключ хранится
/// на устройстве и никогда не отправляется на backend — туда уходит только public.
enum WireGuardKeys {
    struct KeyPair {
        let privateKeyBase64: String
        let publicKeyBase64: String
    }

    static func generate() -> KeyPair {
        let priv = Curve25519.KeyAgreement.PrivateKey()
        return KeyPair(
            privateKeyBase64: priv.rawRepresentation.base64EncodedString(),
            publicKeyBase64: priv.publicKey.rawRepresentation.base64EncodedString()
        )
    }

    static func publicKey(fromPrivateBase64 privateKey: String) -> String? {
        guard
            let data = Data(base64Encoded: privateKey),
            let priv = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
        else { return nil }
        return priv.publicKey.rawRepresentation.base64EncodedString()
    }
}
