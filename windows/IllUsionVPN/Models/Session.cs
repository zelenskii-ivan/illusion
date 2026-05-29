using System.Collections.Generic;
using System.Text;
using System.Text.Json.Serialization;

namespace IllUsionVPN.Models;

public sealed class Session
{
    public sealed class InterfaceConfig
    {
        [JsonPropertyName("address")] public List<string> Address { get; set; } = new();
        [JsonPropertyName("dns")] public List<string> Dns { get; set; } = new();
        [JsonPropertyName("mtu")] public int Mtu { get; set; } = 1420;
    }

    public sealed class Peer
    {
        [JsonPropertyName("publicKey")] public string PublicKey { get; set; } = "";
        [JsonPropertyName("endpoint")] public string Endpoint { get; set; } = "";
        [JsonPropertyName("allowedIPs")] public List<string> AllowedIPs { get; set; } = new();
        [JsonPropertyName("persistentKeepalive")] public int? PersistentKeepalive { get; set; }
    }

    [JsonPropertyName("sessionId")] public string SessionId { get; set; } = "";
    [JsonPropertyName("multihop")] public bool? Multihop { get; set; }
    [JsonPropertyName("interface")] public InterfaceConfig Interface { get; set; } = new();
    [JsonPropertyName("peers")] public List<Peer> Peers { get; set; } = new();
    [JsonPropertyName("expiresAt")] public double ExpiresAt { get; set; }

    /// <summary>Собирает конфигурацию в формате wg-quick для tunnel.dll.</summary>
    public string ToWgQuickConfig(string privateKey)
    {
        var sb = new StringBuilder();
        sb.AppendLine("[Interface]");
        sb.AppendLine($"PrivateKey = {privateKey}");
        sb.AppendLine($"Address = {string.Join(", ", Interface.Address)}");
        sb.AppendLine($"DNS = {string.Join(", ", Interface.Dns)}");
        sb.AppendLine($"MTU = {Interface.Mtu}");
        foreach (var peer in Peers)
        {
            sb.AppendLine();
            sb.AppendLine("[Peer]");
            sb.AppendLine($"PublicKey = {peer.PublicKey}");
            sb.AppendLine($"Endpoint = {peer.Endpoint}");
            sb.AppendLine($"AllowedIPs = {string.Join(", ", peer.AllowedIPs)}");
            if (peer.PersistentKeepalive is int k)
                sb.AppendLine($"PersistentKeepalive = {k}");
        }
        return sb.ToString();
    }
}
