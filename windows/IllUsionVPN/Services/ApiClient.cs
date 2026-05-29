using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading.Tasks;
using IllUsionVPN.Models;

namespace IllUsionVPN.Services;

public sealed class ApiClient
{
    public static readonly ApiClient Shared = new();

    private readonly HttpClient _http = new() { BaseAddress = new Uri("http://localhost:8787") };
    private string? _token;

    public sealed class LoginResponse
    {
        public string token { get; set; } = "";
    }

    public async Task LoginAsync(string email, string password)
    {
        var resp = await _http.PostAsJsonAsync("/api/auth/login", new { email, password });
        resp.EnsureSuccessStatusCode();
        var body = await resp.Content.ReadFromJsonAsync<LoginResponse>();
        _token = body?.token;
        if (_token is not null)
            _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);
    }

    public async Task<List<Server>> FetchServersAsync()
    {
        var resp = await _http.GetFromJsonAsync<ServerListResponse>("/api/servers");
        return resp?.Servers ?? new List<Server>();
    }

    public async Task<Session> CreateSessionAsync(string serverId, string? exitServerId, string publicKey)
    {
        var payload = new Dictionary<string, object> { ["serverId"] = serverId, ["publicKey"] = publicKey };
        if (exitServerId is not null) payload["exitServerId"] = exitServerId;
        var resp = await _http.PostAsJsonAsync("/api/session", payload);
        resp.EnsureSuccessStatusCode();
        return (await resp.Content.ReadFromJsonAsync<Session>())!;
    }
}
