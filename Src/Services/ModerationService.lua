local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local MessageReceiveService = require(script.Parent.MessageReceiveService)
local ApiService = require(script.Parent.ApiService)

local ModerationStatus = require(script.Parent.Parent.Enums.ModerationStatus)
local ModerationType = require(script.Parent.Parent.Enums.ModerationType)
local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local Network = require(script.Parent.Parent.Network.Server)

local DEFAULT_BAN_MESSAGE = "You've been banned from this game."
local DEFAULT_BAN_MESSAGAE_EXPIRY = "You've been banned from this game.\nUnbanned on %s"

local ModerationService = { }

ModerationService.Priority = 0
ModerationService.Reporter = Console.new(`{script.Name}`)

function ModerationService.FetchPlayerModerationStatusAsync(self: ModerationService, player: Player)
	return Promise.new(function(resolve)
		local success, result = ApiService:GetAsync(string.format(ApiPaths.GetModerationStatus, ApiService.ProjectId), {
			userId = player.UserId
		}):await()

		if not success or not result.Success then
			self.Reporter:Warn(`Failed to fetch Moderation status for user; '{player.DisplayName}'`)
			self.Reporter:Debug(result)

			resolve({
				status = "unknown"
			})

			return
		end

		resolve(HttpService:JSONDecode(result.Body))
	end)
end

function ModerationService.OnPlayerAdded(self: ModerationService, player: Player)
	self:FetchPlayerModerationStatusAsync(player)
		:andThen(function(response: ApiModerationStatus)
			if response.status == ModerationStatus.Banned then
				local utcTimeNow = os.time(os.date("!*t"))

				if response.expiry then
					local delta = response.expiry - utcTimeNow

					if delta > 0 then
						self.Reporter:Debug(`Player '{player.DisplayName}' ban has expired! Not kicking them from the Server!`)

						return
					end
				end

				if response.expiry then
					player:Kick(
						string.format(
							DEFAULT_BAN_MESSAGAE_EXPIRY,
							DateTime.fromUnixTimestamp(utcTimeNow):FormatLocalTime("LLL", "en-us")
						)
					)
				else
					player:Kick(DEFAULT_BAN_MESSAGE)
				end
			elseif response.status == ModerationStatus.Clear then
				self.Reporter:Debug(`Player '{player.DisplayName}' moderation status is clear!`)
			else
				self.Reporter:Debug(`Player '{player.DisplayName}' moderation status is unknown; '{response.status or "NULL"}'`)
			end
		end)
end

function ModerationService.OnStart(self: ModerationService)
	MessageReceiveService.OnModeration:Connect(function(packet: ModerationPacket)
		-- todo: implement action on message service request
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		self:OnPlayerAdded(player)
	end)

	for _, player: Player in Players:GetPlayers() do
		task.defer(function()
			self:OnPlayerAdded(player)
		end)
	end
end

export type ModerationService = typeof(ModerationService)
export type ModerationPacket = {
	id: string,
	message: string,
	type: string
}

export type ApiModerationStatus = {
	status: string,
	reason: string?,
	expiry: number?
}

return ModerationService