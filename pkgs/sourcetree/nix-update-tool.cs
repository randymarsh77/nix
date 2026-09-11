using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;

// Add namespace to avoid conflict with other entry points
class NixUpdateTool
{
	private static readonly HttpClient _httpClient = new HttpClient();

	static NixUpdateTool()
	{
		// Set User-Agent for GitHub API requests
		_httpClient.DefaultRequestHeaders.Add("User-Agent", "NixUpdateTool/1.0");
	}

	class VersionInfo
	{
		public string SortKey { get; set; }
		public string Version { get; set; }
	}

	enum UpdateType
	{
		SparkleXmlFeed,
		GitHubTags
	}

	class AppInfo
	{
		public string FilePath { get; set; }
		public string FeedUrl { get; set; }
		public UpdateType UpdateType { get; set; }
		public string CurrentVersion { get; set; }
	}

	static async Task Main(string[] args)
	{
		if (args.Length < 1)
		{
			Console.WriteLine("Usage: nix-update-tool <root-directory>");
			Environment.Exit(1);
			return;
		}

		string rootDirectory = args[0];

		try
		{
			// Scan for .nix files with update feed
			List<AppInfo> appInfos = ScanForUpdatableApps(rootDirectory);

			if (appInfos.Count == 0)
			{
				Console.WriteLine("No updatable Nix packages found.");
				return;
			}

			Console.WriteLine($"Found {appInfos.Count} updatable Nix packages.");
			int updated = 0;

			foreach (var appInfo in appInfos)
			{
				Console.WriteLine($"\nProcessing: {Path.GetFileName(appInfo.FilePath)}");
				Console.WriteLine($"Source: {appInfo.FeedUrl} ({appInfo.UpdateType})");

				try
				{
					string latestVersion = await GetLatestVersion(appInfo);

					if (string.IsNullOrEmpty(latestVersion))
					{
						Console.WriteLine("Failed to get latest version. Skipping.");
						continue;
					}

					Console.WriteLine($"Current version: {appInfo.CurrentVersion}");
					Console.WriteLine($"Latest version: {latestVersion}");

					if (latestVersion != appInfo.CurrentVersion)
					{
						string sha = await GetSHA256(latestVersion, appInfo);
						await UpdateNixFile(appInfo.FilePath, latestVersion, sha);
						Console.WriteLine($"Updated to version {latestVersion}");
						updated++;
					}
					else
					{
						Console.WriteLine("Already up to date");
					}
				}
				catch (Exception ex)
				{
					Console.WriteLine($"Error updating {appInfo.FilePath}: {ex.Message}");
				}
			}

			Console.WriteLine($"\nSummary: Updated {updated} of {appInfos.Count} packages");
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error: {ex.Message}");
			Environment.Exit(1);
		}
	}

	static List<AppInfo> ScanForUpdatableApps(string rootDirectory)
	{
		var appInfos = new List<AppInfo>();
		var nixFiles = Directory.GetFiles(rootDirectory, "*.nix", SearchOption.AllDirectories);

		foreach (var nixFile in nixFiles)
		{
			try
			{
				string content = File.ReadAllText(nixFile);
				AppInfo appInfo = null;

				// Check for feed URL marker
				var feedMatch = Regex.Match(content, @"#\s*nix-update-tool\.feed:\s*(.+)");
				if (feedMatch.Success)
				{
					string feedUrl = feedMatch.Groups[1].Value.Trim();
					appInfo = new AppInfo
					{
						FilePath = nixFile,
						FeedUrl = feedUrl,
						UpdateType = UpdateType.SparkleXmlFeed
					};
				}

				// Check for GitHub tags URL marker
				var tagsMatch = Regex.Match(content, @"#\s*nix-update-tool\.tags:\s*(.+)");
				if (tagsMatch.Success && appInfo == null) // Only if not already found
				{
					string repoUrl = tagsMatch.Groups[1].Value.Trim();
					string apiUrl = ConvertGitHubUrlToApiUrl(repoUrl);
					appInfo = new AppInfo
					{
						FilePath = nixFile,
						FeedUrl = apiUrl,
						UpdateType = UpdateType.GitHubTags
					};
				}

				if (appInfo != null)
				{
					// Extract the current version
					var versionMatch = Regex.Match(content, @"version\s*=\s*""([^""]+)""");
					if (versionMatch.Success)
					{
						appInfo.CurrentVersion = versionMatch.Groups[1].Value;
						appInfos.Add(appInfo);
					}
				}
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error scanning {nixFile}: {ex.Message}");
			}
		}

		return appInfos;
	}

	static string ConvertGitHubUrlToApiUrl(string url)
	{
		// Convert GitHub repository URL to tags API URL
		// Example: https://github.com/waf/CSharpRepl -> https://api.github.com/repos/waf/CSharpRepl/tags
		var match = Regex.Match(url, @"https://github\.com/([^/]+)/([^/]+)");
		if (match.Success)
		{
			string owner = match.Groups[1].Value;
			string repo = match.Groups[2].Value;
			return $"https://api.github.com/repos/{owner}/{repo}/tags";
		}

		return url; // Return original if not a GitHub URL
	}

	static async Task<string> GetLatestVersion(AppInfo appInfo)
	{
		try
		{
			switch (appInfo.UpdateType)
			{
				case UpdateType.SparkleXmlFeed:
					return await GetLatestVersionFromSparkleXml(appInfo.FeedUrl);
				case UpdateType.GitHubTags:
					return await GetLatestVersionFromGitHubTags(appInfo.FeedUrl);
				default:
					throw new Exception($"Unsupported update type: {appInfo.UpdateType}");
			}
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error fetching latest version: {ex.Message}");
			throw;
		}
	}

	static async Task<string> GetLatestVersionFromSparkleXml(string feedUrl)
	{
		var xmlDoc = await FetchXmlData(feedUrl);
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

	static async Task<string> GetLatestVersionFromGitHubTags(string apiUrl)
	{
		try
		{
			Console.WriteLine($"Fetching GitHub tags from: {apiUrl}");
			var json = await _httpClient.GetStringAsync(apiUrl);

			// Debug: print first part of JSON response
			Console.WriteLine($"Received JSON response: {json.Substring(0, Math.Min(json.Length, 200))}...");

			var options = new JsonSerializerOptions
			{
				PropertyNameCaseInsensitive = true
			};

			var tags = JsonSerializer.Deserialize<List<GitHubTag>>(json, options);

			if (tags == null)
			{
				throw new Exception("Failed to deserialize JSON response");
			}

			if (tags.Count == 0)
			{
				throw new Exception("No tags found in GitHub repository");
			}

			var versions = new List<VersionInfo>();

			foreach (var tag in tags)
			{
				if (tag == null || string.IsNullOrEmpty(tag.Name))
				{
					Console.WriteLine("Skipping null or invalid tag entry");
					continue;
				}

				// Remove 'v' prefix if present
				string version = tag.Name;
				if (version.StartsWith("v", StringComparison.OrdinalIgnoreCase))
				{
					version = version[1..];
				}

				versions.Add(new VersionInfo
				{
					SortKey = ParseVersion(version),
					Version = version
				});
			}

			if (versions.Count == 0)
			{
				throw new Exception("No valid version tags found");
			}

			// Sort versions in descending order
			versions = versions.OrderByDescending(v => v.SortKey).ToList();

			Console.WriteLine($"Latest version found: {versions[0].Version}");
			return versions[0].Version;
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error in GetLatestVersionFromGitHubTags: {ex.Message}");
			Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
			throw;
		}
	}

	static async Task<XmlDocument> FetchXmlData(string url)
	{
		var xmlContent = await _httpClient.GetStringAsync(url);
		var xmlDoc = new XmlDocument();
		xmlDoc.LoadXml(xmlContent);
		return xmlDoc;
	}

	static string ParseVersion(string versionStr)
	{
		// Split version into components
		var parts = Regex.Split(versionStr, @"[._-]");
		// Convert number parts to integers and pad with zeros
		var paddedParts = parts.Select(part =>
		{
			// Skip empty parts
			if (string.IsNullOrWhiteSpace(part))
				return "";

			if (int.TryParse(part, out var num))
				return num.ToString().PadLeft(10, '0');
			return part;
		}).Where(p => !string.IsNullOrEmpty(p)); // Filter out empty parts

		return string.Join(".", paddedParts);
	}

	static async Task<string> GetSHA256(string version, AppInfo appInfo)
	{
		// First check if this is a NuGet package
		string nixContent = await File.ReadAllTextAsync(appInfo.FilePath);
		bool isNuGetPackage = nixContent.Contains("buildDotnetGlobalTool");

		if (isNuGetPackage)
		{
			Console.WriteLine("Detected buildDotnetGlobalTool package, using NuGet SHA calculation");
			return await GetNuGetPackageSHA256(appInfo.FilePath, version);
		}

		return appInfo.UpdateType switch
		{
			UpdateType.SparkleXmlFeed => await GetSHA256ForDirectDownload(version, appInfo.FilePath),
			UpdateType.GitHubTags => await GetSHA256ForGitHubRelease(version, appInfo.FeedUrl),
			_ => throw new Exception($"Unsupported update type: {appInfo.UpdateType}")
		};
	}

	static async Task<string> GetNuGetPackageSHA256(string nixFilePath, string version)
	{
		try
		{
			// Extract package name from nix file
			string nixContent = await File.ReadAllTextAsync(nixFilePath);

			var pnameMatch = Regex.Match(nixContent, @"pname\s*=\s*""([^""]+)""");
			if (!pnameMatch.Success)
			{
				throw new Exception("Could not find pname in NuGet package definition");
			}

			string pname = pnameMatch.Groups[1].Value;
			Console.WriteLine($"NuGet package: {pname} version {version}");

			// Create temporary directory
			string tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
			Directory.CreateDirectory(tempDir);

			try
			{
				// Step 1: Get the exact package ID (correct casing) from NuGet API
				string packageIdLower = pname.ToLower();
				string nugetApiUrl = $"https://api.nuget.org/v3/registration5-semver1/{packageIdLower}/{version}.json";

				Console.WriteLine($"Finding package ID from {nugetApiUrl}");

				string exactPackageId;
				try
				{
					// Fetch package metadata to get exact ID
					string packageInfo = await _httpClient.GetStringAsync(nugetApiUrl);
					var infoOptions = new JsonSerializerOptions
					{
						PropertyNameCaseInsensitive = true
					};

					var document = JsonDocument.Parse(packageInfo);
					var idProp = document.RootElement.GetProperty("id");
					exactPackageId = idProp.GetString();

					if (string.IsNullOrEmpty(exactPackageId))
					{
						// If ID not found, fall back to provided name
						exactPackageId = pname;
					}
				}
				catch (Exception)
				{
					// If metadata lookup fails, just use the provided name
					exactPackageId = pname;
					Console.WriteLine($"Package metadata lookup failed, using {pname} as package ID");
				}

				// Step 2: Construct the download URL and download the .nupkg file
				string downloadUrl = $"https://api.nuget.org/v3-flatcontainer/{exactPackageId.ToLower()}/{version}/{exactPackageId}.{version}.nupkg";
				string nupkgPath = Path.Combine(tempDir, $"{exactPackageId}.{version}.nupkg");

				Console.WriteLine($"Downloading from {downloadUrl}");

				using (var response = await _httpClient.GetAsync(downloadUrl))
				{
					response.EnsureSuccessStatusCode();
					using var fileStream = File.Create(nupkgPath);
					await response.Content.CopyToAsync(fileStream);
				}

				// Step 3: Calculate the hash using nix-hash (using bash only for this part)
				var startInfo = new ProcessStartInfo
				{
					FileName = "nix-hash",
					Arguments = $"--flat --type sha256 --base64 \"{nupkgPath}\"",
					RedirectStandardOutput = true,
					RedirectStandardError = true,
					UseShellExecute = false,
					CreateNoWindow = true
				};

				using var process = Process.Start(startInfo);
				var output = await process.StandardOutput.ReadToEndAsync();
				var error = await process.StandardError.ReadToEndAsync();

				await process.WaitForExitAsync();

				if (process.ExitCode != 0)
				{
					throw new Exception($"Failed to calculate NuGet SHA: {error}");
				}

				string hash = output.Trim();

				if (string.IsNullOrEmpty(hash))
				{
					throw new Exception("Failed to extract NuGet hash");
				}

				Console.WriteLine($"Generated NuGet package hash: {hash}");
				return $"sha256-{hash}";
			}
			finally
			{
				// Clean up the temporary directory and its contents
				if (Directory.Exists(tempDir))
				{
					try
					{
						Console.WriteLine($"Cleaning up temporary directory: {tempDir}");
						Directory.Delete(tempDir, true);
					}
					catch (Exception ex)
					{
						Console.WriteLine($"Warning: Failed to clean up temporary directory: {ex.Message}");
					}
				}
			}
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error calculating NuGet SHA256: {ex.Message}");
			Console.Error.WriteLine(ex.StackTrace);
			throw;
		}
	}

	static async Task<string> GetSHA256ForGitHubRelease(string version, string repoApiUrl)
	{
		try
		{
			// Extract owner and repo name from API URL
			var match = Regex.Match(repoApiUrl, @"https://api\.github\.com/repos/([^/]+)/([^/]+)");
			if (!match.Success)
			{
				throw new Exception("Could not parse GitHub repository information from API URL");
			}

			string owner = match.Groups[1].Value;
			string repo = match.Groups[2].Value;

			// Get release information by tag
			string releaseTag = version.StartsWith("v") ? version : $"v{version}";
			string releaseInfoUrl = $"https://api.github.com/repos/{owner}/{repo}/releases/tags/{releaseTag}";

			// Alternatively, try without the 'v' prefix if it fails
			Console.WriteLine($"Fetching release info from: {releaseInfoUrl}");

			HttpResponseMessage response;
			try
			{
				response = await _httpClient.GetAsync(releaseInfoUrl);
				if (!response.IsSuccessStatusCode)
				{
					// Try without the 'v' prefix
					releaseTag = version;
					releaseInfoUrl = $"https://api.github.com/repos/{owner}/{repo}/releases/tags/{releaseTag}";
					Console.WriteLine($"Retrying with: {releaseInfoUrl}");
					response = await _httpClient.GetAsync(releaseInfoUrl);
				}
			}
			catch (Exception ex)
			{
				throw new Exception($"Failed to fetch GitHub release: {ex.Message}");
			}

			if (!response.IsSuccessStatusCode)
			{
				// If we still can't get the release, try the fallback download URL
				Console.WriteLine("Release not found, trying fallback URL...");
				string fallbackUrl = $"https://github.com/{owner}/{repo}/archive/refs/tags/{releaseTag}.tar.gz";
				return await GetSHA256ForUrl(fallbackUrl);
			}

			// Parse release info to extract assets
			string releaseJson = await response.Content.ReadAsStringAsync();
			Console.WriteLine($"Received release info: {releaseJson.Substring(0, Math.Min(releaseJson.Length, 200))}...");

			var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
			var releaseInfo = JsonSerializer.Deserialize<GitHubRelease>(releaseJson, options);

			if (releaseInfo == null || releaseInfo.Assets == null || releaseInfo.Assets.Count == 0)
			{
				// If no assets are available, use the archive URL
				string archiveUrl = $"https://github.com/{owner}/{repo}/archive/refs/tags/{releaseTag}.tar.gz";
				Console.WriteLine($"No assets found, using archive URL: {archiveUrl}");
				return await GetSHA256ForUrl(archiveUrl);
			}

			// Try to find a suitable asset (prefer .zip or .tar.gz)
			var asset = FindSuitableAsset(releaseInfo.Assets);

			if (asset != null)
			{
				Console.WriteLine($"Found suitable asset: {asset.Name} ({asset.BrowserDownloadUrl})");
				return await GetSHA256ForUrl(asset.BrowserDownloadUrl);
			}
			else
			{
				// Fallback to source tarball
				string archiveUrl = $"https://github.com/{owner}/{repo}/archive/refs/tags/{releaseTag}.tar.gz";
				Console.WriteLine($"No suitable assets found, using archive URL: {archiveUrl}");
				return await GetSHA256ForUrl(archiveUrl);
			}
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error in GetSHA256ForGitHubRelease: {ex.Message}");
			Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
			throw;
		}
	}

	private static GitHubAsset FindSuitableAsset(List<GitHubAsset> assets)
	{
		// Define preferred extensions
		var preferredExtensions = new[] { ".zip", ".tar.gz", ".tgz", ".tar.xz", ".pkg", ".dmg" };

		// First, try to find assets with preferred extensions
		foreach (var ext in preferredExtensions)
		{
			var asset = assets.FirstOrDefault(a => a.Name.EndsWith(ext, StringComparison.OrdinalIgnoreCase));
			if (asset != null)
			{
				return asset;
			}
		}

		// If no preferred extension found, return the first asset
		return assets.FirstOrDefault();
	}

	// GitHub release API response classes
	private class GitHubRelease
	{
		public string Url { get; set; } = "";
		public string HtmlUrl { get; set; } = "";
		public string AssetsUrl { get; set; } = "";
		public string UploadUrl { get; set; } = "";
		public string TarballUrl { get; set; } = "";
		public string ZipballUrl { get; set; } = "";
		public int Id { get; set; }
		public string TagName { get; set; } = "";
		public bool Draft { get; set; }
		public bool Prerelease { get; set; }
		public string Name { get; set; } = "";
		public string Body { get; set; } = "";
		public List<GitHubAsset> Assets { get; set; } = new List<GitHubAsset>();
	}

	private class GitHubAsset
	{
		public string Url { get; set; } = "";
		public string Name { get; set; } = "";
		public string Label { get; set; } = "";
		public string ContentType { get; set; } = "";
		public long Size { get; set; }
		public string BrowserDownloadUrl { get; set; } = "";
	}

	static async Task<string> GetSHA256ForDirectDownload(string version, string nixFilePath)
	{
		// Extract URL pattern from the nix file
		string nixContent = await File.ReadAllTextAsync(nixFilePath);
		var urlMatch = Regex.Match(nixContent, @"url\s*=\s*""([^""]*\$\{version\}[^""]*)""");
		if (!urlMatch.Success)
		{
			throw new Exception("Could not determine URL pattern from nix file");
		}

		string urlPattern = urlMatch.Groups[1].Value;
		string url = urlPattern.Replace("${version}", version);

		return await GetSHA256ForUrl(url);
	}

	static async Task<string> GetSHA256ForUrl(string url)
	{
		var startInfo = new ProcessStartInfo
		{
			FileName = "/bin/bash",
			Arguments = $"-c \"curl -L '{url}' | nix-hash --flat --type sha256 --base64 /dev/stdin\"",
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

	static async Task UpdateNixFile(string nixFilePath, string version, string sha)
	{
		try
		{
			var nixContent = await File.ReadAllTextAsync(nixFilePath);

			// Replace version
			nixContent = Regex.Replace(nixContent, @"version\s*=\s*""[^""]+""", $@"version = ""{version}""");

			// Check for the patterns in the file
			bool hasNugetSha256 = nixContent.Contains("nugetSha256");
			bool hasNugetHash = nixContent.Contains("nugetHash");
			bool hasRegularSha = nixContent.Contains("sha256 =") && !hasNugetSha256 && !hasNugetHash;

			// Replace the appropriate SHA256 pattern
			if (hasNugetSha256)
			{
				Console.WriteLine("Replacing nugetSha256 pattern");
				nixContent = Regex.Replace(nixContent, @"nugetSha256\s*=\s*""[^""]+""", $@"nugetSha256 = ""{sha}""");
			}
			else if (hasNugetHash)
			{
				Console.WriteLine("Replacing nugetHash pattern");
				nixContent = Regex.Replace(nixContent, @"nugetHash\s*=\s*""[^""]+""", $@"nugetHash = ""{sha}""");
			}
			else if (hasRegularSha)
			{
				Console.WriteLine("Replacing regular sha256 pattern");
				nixContent = Regex.Replace(nixContent, @"sha256\s*=\s*""[^""]+""", $@"sha256 = ""{sha}""");
			}
			else
			{
				Console.WriteLine("Warning: No SHA256 pattern found to replace");
			}

			await File.WriteAllTextAsync(nixFilePath, nixContent);
			Console.WriteLine($"Updated {nixFilePath} with version {version} and SHA {sha}");
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine($"Error updating nix file: {ex.Message}");
			throw;
		}
	}

	// JSON class for GitHub tags API response
	private class GitHubTag
	{
		public string Name { get; set; } = ""; // Initialize to prevent null references
		public string ZipballUrl { get; set; } = "";
		public string TarballUrl { get; set; } = "";
		public GitHubCommit Commit { get; set; } = new GitHubCommit();
		public string NodeId { get; set; } = "";
	}

	private class GitHubCommit
	{
		public string Sha { get; set; } = "";
		public string Url { get; set; } = "";
	}
}
