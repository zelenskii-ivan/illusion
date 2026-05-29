using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Sockets;
using System.Threading.Tasks;
using IllUsionVPN.Models;

namespace IllUsionVPN.Services;

/// <summary>Замер задержки до сервера через TCP-подключение (RTT).</summary>
public static class LatencyProbe
{
    public static async Task<int?> MeasureAsync(string host, int port, int timeoutMs = 2000)
    {
        try
        {
            using var client = new TcpClient();
            var sw = Stopwatch.StartNew();
            var connectTask = client.ConnectAsync(host, port);
            var completed = await Task.WhenAny(connectTask, Task.Delay(timeoutMs));
            if (completed != connectTask || !client.Connected) return null;
            sw.Stop();
            return (int)sw.ElapsedMilliseconds;
        }
        catch
        {
            return null;
        }
    }

    public static async Task<List<Server>> RankAsync(List<Server> servers)
    {
        var tasks = servers.Select(async s =>
        {
            s.LatencyMs = await MeasureAsync(s.Host, s.Port);
            return s;
        });
        var measured = (await Task.WhenAll(tasks)).ToList();
        return measured.OrderBy(s => s.LatencyMs ?? int.MaxValue).ToList();
    }
}
