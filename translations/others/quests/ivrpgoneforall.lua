require "/scripts/util.lua"

function init()
	quest.setCompletionText("RPG Growth está a extinguir o uso desta missão. Por favor, não se preocupe que tenha sido concluída.")
	quest.setFailureText("RPG Growth Growth está a extinguir o uso desta missão. Por favor, não se preocupe que tenha sido fracassada.")
	quest.fail()
end

function update(dt)
	
end
