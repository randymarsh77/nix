using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;

// Add namespace to avoid conflict with other entry points
class SourcetreeUpdater
{
	// Use current working directory to find default.nix instead of AppDomain.CurrentDomain.BaseDirectory
	private static readonly string NixFilePath = Path.Combine(Directory.GetCurrentDirectory(), "default.nix");
	private const string FeedUrl = "https://product-downloads.atlassian.com/software/sourcetree/Appcast/SparkleAppcastGroup4.xml";

	class VersionInfo
	{
		public string SortKey { get; set; }
		public string Version { get; set; }
	}

	static async Task Main(string[] args)
	{
		try
		{
			var latestVersion = await GetLatestVersion();
			var currentVersion = GetCurrentVersion();

			if (latestVersion != currentVersion)
			{
				Console.WriteLine($"Updating Sourcetree from version {currentVersion} to {latestVersion}");
				var sha = await GetSHA256(latestVersion);
				await UpdateNixFile(latestVersion, sha);
				Console.WriteLine($"Sourcetree updated to version {latestVersion}");
			}
			else
			{
				Console.WriteLine("Sourcetree is already up to date");
			}
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Update failed: {ex.Message}");
			Environment.Exit(1);
		}
	}

	static async Task<string> GetLatestVersion()
	{
		try
		{
			var xmlDoc = await FetchXmlData(FeedUrl);
			var items = xmlDoc.GetElementsByTagName("item");
			var versions = new List<VersionInfo>();

			foreach (XmlNode item in items)
			{
				var enclosures = item.SelectNodes("enclosure");
				if (enclosures != null && enclosures.Count > 0)
				{
					var enclosure = enclosures[0];
					if (enclosure.Attributes != null)
					{
						var shortVersion = enclosure.Attributes["sparkle:shortVersionString"]?.Value;
						var buildVersion = enclosure.Attributes["sparkle:version"]?.Value;

						if (!string.IsNullOrEmpty(shortVersion) && !string.IsNullOrEmpty(buildVersion))
						{
							versions.Add(new VersionInfo
							{
								SortKey = ParseVersion($"{shortVersion}_{buildVersion}"),
								Version = $"{shortVersion}_{buildVersion}"
							});
						}
					}
				}
			}

			// Sort versions in descending order
			versions = versions.OrderByDescending(v => v.SortKey).ToList();

			if (versions.Count > 0)
			{
				return versions[0].Version;
			}

			throw new Exception("No version information found in feed");
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error fetching latest version: {ex.Message}");
			throw;
		}
	}

	static async Task<XmlDocument> FetchXmlData(string url)
	{
		using var httpClient = new HttpClient();
		var xmlContent = await httpClient.GetStringAsync(url);

		var xmlDoc = new XmlDocument();
		xmlDoc.LoadXml(xmlContent);
		return xmlDoc;
	}

	static string ParseVersion(string versionStr)
	{
		// Split version into components
		var parts = Regex.Split(versionStr, @"[._]");
		// Convert number parts to integers and pad with zeros
		var paddedParts = parts.Select(part =>
		{
			if (int.TryParse(part, out var num))
				return num.ToString().PadLeft(10, '0');
			return part;
		});

		return string.Join(".", paddedParts);
	}

	static async Task<string> GetSHA256(string version)
	{
		var url = $"https://product-downloads.atlassian.com/software/sourcetree/ga/Sourcetree_{version}.zip";

		var startInfo = new ProcessStartInfo
		{
			FileName = "/bin/bash",
			Arguments = $"-c \"curl -L '{url}' | nix-hash --type sha256 --base64 /dev/stdin\"",
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			UseShellExecute = false,
			CreateNoWindow = true
		};

		try
		{
			using var process = Process.Start(startInfo);
			var output = await process.StandardOutput.ReadToEndAsync();
			await process.WaitForExitAsync();

			if (process.ExitCode != 0)
			{
				var error = await process.StandardError.ReadToEndAsync();
				throw new Exception($"SHA256 calculation failed: {error}");
			}

			return $"sha256-{output.Trim()}";
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error getting SHA256: {ex.Message}");
			throw;
		}
	}

	static string GetCurrentVersion()
	{
		try
		{
			var nixContent = File.ReadAllText(NixFilePath);
			var versionMatch = Regex.Match(nixContent, @"version\s*=\s*""([^""]+)""");

			if (versionMatch.Success && versionMatch.Groups.Count > 1)
			{
				return versionMatch.Groups[1].Value;
			}

			throw new Exception("Could not extract current version from nix file");
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error getting current version: {ex.Message}");
			throw;
		}
	}

	static async Task UpdateNixFile(string version, string sha)
	{
		try
		{
			var nixContent = await File.ReadAllTextAsync(NixFilePath);

			// Replace version
			nixContent = Regex.Replace(nixContent, @"version\s*=\s*""[^""]+""", $@"version = ""{version}""");

			// Replace SHA256
			nixContent = Regex.Replace(nixContent, @"sha256\s*=\s*""[^""]+""", $@"sha256 = ""{sha}""");

			await File.WriteAllTextAsync(NixFilePath, nixContent);
			Console.WriteLine($"Updated {NixFilePath} with version {version} and SHA {sha}");
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error updating nix file: {ex.Message}");
			throw;
		}
	}
}
