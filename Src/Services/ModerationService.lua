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
local DEFAULT_KICK_MESSAGE = "You've been kicked from this game."

local ModerationService = { }

ModerationService.Priority = 0
ModerationService.Reporter = Console.new(`{script.Name}`)

function ModerationService.InvokeKick(self: ModerationService, player: Player, _message: string?)
	local message = _message ~= "" and _message or nil

	local messageObject = `\n`

	if message then
		messageObject ..= message
	else
		messageObject ..= DEFAULT_KICK_MESSAGE
	end

	player:Kick(messageObject)
end

function ModerationService.InvokeBan(self: ModerationService, player: Player, _message: string?, _expiry: string?)
	local message = _message ~= "" and _message or nil
	local expiry = _expiry and DateTime.fromIsoDate(_expiry) or nil

	local messageObject = `\n`

	if message then
		messageObject ..= message
	else
		messageObject ..= DEFAULT_BAN_MESSAGE
	end

	if expiry then
		messageObject ..= ` || Ban Active Until: {expiry:FormatUniversalTime("LLL", "en-us")}`
	end

	player:Kick(messageObject)
end

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
					local datetime = DateTime.fromIsoDate(response.expiry)
					local delta = datetime.UnixTimestamp - utcTimeNow

					if delta > 0 then
						self.Reporter:Debug(`Player '{player.DisplayName}' ban has expired! Not kicking them from the Server!`)

						return
					end
				end

				self:InvokeBan(player, response.reason, response.expiry)
			elseif response.status == ModerationStatus.Clear then
				self.Reporter:Debug(`Player '{player.DisplayName}' moderation status is clear!`)
			else
				self.Reporter:Debug(`Player '{player.DisplayName}' moderation status is unknown; '{response.status or "NULL"}'`)
			end
		end)
end

function ModerationService.OnStart(self: ModerationService)
	MessageReceiveService.OnModeration:Connect(function(packet: ModerationPacket)
		local player = Players:GetPlayerByUserId(packet.userId)

		self.Reporter:Debug(packet)

		if packet.type == ModerationType.Ban then
			self:InvokeBan(player, packet.reason, packet.expiry)
		elseif packet.type == ModerationType.Kick then
			self:InvokeKick(player, packet.reason)
		elseif packet.type == ModerationType.Warn then
			if not packet.reason or packet.reason == "" then
				self.Reporter:Warn(`Dropping warn request for '{player.DisplayName}' - no warning message provided`)
				
				return
			end

			Network.BroadcastWarningMessage.Fire(player, packet.reason :: string)
		end
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
	reason: string?,
	expiry: string?,
	userId: number,
	type: string
}

export type ApiModerationStatus = {
	status: string,
	reason: string?,
	expiry: string?
}

return ModerationService