local json = require("cjson");
local secret = require("secret");


--[[

should add logging of responses and ips and then add thing in secret dictating how many log entries to save
save log entries by simply appending to a file, and then use the wc -l command to count lines,
one line per entry
]]

--Payload and url info
local payload = {
	["secretapikey"] = secret.secretapikey,
	["apikey"] = secret.apikey,
	["content"] = "",
	["ttl"] = "600"
}

local url = string.format("https://porkbun.com/api/json/v3/dns/editByNameType/%s/A/%s",
	secret.domain,
	secret.subdomain
);

--Get our IP
local ipProg = io.popen("curl -s ifconfig.me", "r");
local ip = ipProg:read("*a");
ipProg:close();

payload["content"] = ip;

--Send the payload
local strPayload = json.encode(payload);

local resProg = io.popen(
	string.format([[curl -s -g -X POST -H "Content-Type: application/json" -d '%s' %s]], strPayload, url),
	"r"
);

local res = resProg:read("*a");
resProg:close();

--Write the logfile

local function getLineCount(filename)
	local progFile = io.popen(string.format("wc -l %s", filename), "r");
	local ret = progFile:read("*a");
	progFile:close();
	return tonumber(ret:match("%d+"));
end

--Make sure the logfile exists
os.execute("touch newLog");


local newLog = io.open("newLog", "a");
newLog:write(string.format("%s, %s, %s\n", res, os.date(), ip));

if getLineCount("newLog") > secret.logCount then
	os.execute("cp -u newLog oldLog");
	os.execute("rm newLog");
end
