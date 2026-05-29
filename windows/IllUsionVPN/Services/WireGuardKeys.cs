using System;
using System.Security.Cryptography;

namespace IllUsionVPN.Services;

/// <summary>
/// Генерация пары ключей WireGuard (Curve25519/X25519). Приватный ключ остаётся
/// на устройстве, на backend уходит только публичный.
/// </summary>
public static class WireGuardKeys
{
    public readonly record struct KeyPair(string PrivateKeyBase64, string PublicKeyBase64);

    public static KeyPair Generate()
    {
        // X25519 через ECDiffieHellman (доступно в .NET 8 на Windows CNG).
        using var ecdh = ECDiffieHellman.Create();
        // Примечание: для строгой совместимости с WireGuard используйте
        // нативную обвязку (NSec/libsodium). Здесь — каркас.
        var priv = RandomNumberGenerator.GetBytes(32);
        ClampPrivateKey(priv);
        var pub = X25519PublicFromPrivate(priv);
        return new KeyPair(Convert.ToBase64String(priv), Convert.ToBase64String(pub));
    }

    private static void ClampPrivateKey(byte[] k)
    {
        k[0] &= 248;
        k[31] &= 127;
        k[31] |= 64;
    }

    // Заглушка скалярного умножения X25519. Замените на libsodium/NSec в проде.
    private static byte[] X25519PublicFromPrivate(byte[] privateKey)
    {
        // TODO: интегрировать NSec.Cryptography для корректного X25519.
        var pub = new byte[32];
        RandomNumberGenerator.Fill(pub);
        return pub;
    }
}
