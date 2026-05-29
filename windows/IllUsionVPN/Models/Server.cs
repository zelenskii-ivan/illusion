using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace IllUsionVPN.Models;

public sealed class Server
{
    [JsonPropertyName("id")] public string Id { get; set; } = "";
    [JsonPropertyName("country")] public string Country { get; set; } = "";
    [JsonPropertyName("countryCode")] public string CountryCode { get; set; } = "";
    [JsonPropertyName("city")] public string City { get; set; } = "";
    [JsonPropertyName("flag")] public string? Flag { get; set; }
    [JsonPropertyName("host")] public string Host { get; set; } = "";
    [JsonPropertyName("port")] public int Port { get; set; }
    [JsonPropertyName("load")] public int Load { get; set; }
    [JsonPropertyName("features")] public List<string> Features { get; set; } = new();
    [JsonPropertyName("tier")] public string Tier { get; set; } = "free";

    [JsonIgnore] public int? LatencyMs { get; set; }

    [JsonIgnore] public bool SupportsMultihopExit => Features.Contains("multihop-exit");
    [JsonIgnore] public string Display => $"{City}, {Country}";
    [JsonIgnore] public string LatencyLabel => LatencyMs is int ms ? $"{ms} ms" : "—";
}

public sealed class ServerListResponse
{
    [JsonPropertyName("servers")] public List<Server> Servers { get; set; } = new();
}
