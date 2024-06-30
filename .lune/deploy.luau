local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")

local artifact = process.args[1]
local commitHash = process.env.GITHUB_SHA
local authorization = process.env.SDK_ARTIFACT_UPLOAD_SECRET

local multiformUuid = `SDK_WORKFLOW.{math.random()}`
local multiformContentBoundary = `{multiformUuid}`
local multiformContent = ""

multiformContent ..= `--{multiformContentBoundary}\r\n`
multiformContent ..= `Content-Disposition: form-data; name="commitHash"\r\n`
multiformContent ..= `Content-Type: application/json\r\n`

multiformContent ..= `\r\n`
multiformContent ..= `{commitHash}\r\n`

multiformContent ..= `--{multiformContentBoundary}\r\n`
multiformContent ..= `Content-Disposition: form-data; name="file"; filename="file.rbxm"\r\n`
multiformContent ..= `Content-Type: application/octet-stream\r\n`

multiformContent ..= `\r\n`
multiformContent ..= `{fs.readFile(artifact)}\r\n`

multiformContent ..= `--{multiformContentBoundary}--\r\n`

print(net.request({
    url = "https://preview.metrik.app/api/sdk/upload-artifact",
    method = "POST",
    headers = {
        ["Authorization"] = `Bearer {authorization}`,
        ["content-type"] = `multipart/form-data; boundary={multiformContentBoundary}`
    },
    body = multiformContent
}))