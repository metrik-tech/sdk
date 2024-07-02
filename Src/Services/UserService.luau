local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local ApiService = require(script.Parent.ApiService)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local UserService = { }

UserService.Priority = 0
UserService.Reporter = Console.new(`{script.Name}`)

UserService.UserStore = {} :: { [number]: User }

function UserService.GetUserAsync(self: UserService, userId: number)
	return Promise.new(function(resolve, reject)
		if self.UserStore[userId] then
			return resolve(self.UserStore[userId])
		end

		ApiService:GetAsync(string.format(ApiPaths.GetUserInformation, ApiService.ProjectId, userId), { }):andThen(function(response)
			local userInformation = HttpService:JSONDecode(response.Body)

			self.UserStore[userId] = {
				Description = userInformation.description,
				Created = DateTime.fromIsoDate(userInformation.created),
				IsBanned = userInformation.IsBanned,
				ExternalAppDisplayName = userInformation.ExternalAppDisplayName,
				HasVerifiedBadge = userInformation.HasVerifiedBadge,
				Id = userInformation.Id,
				Name = userInformation.Name,
				DisplayName = userInformation.DisplayName
			}

			resolve(self.UserStore[userId])
		end)

		return
	end)
end

export type UserService = typeof(UserService)
export type User = {
	Description: string,
	Created: DateTime,
	IsBanned: boolean,
	ExternalAppDisplayName: string?,
	HasVerifiedBadge: boolean,
	Id: number,
	Name: string,
	DisplayName: string
}

return UserService