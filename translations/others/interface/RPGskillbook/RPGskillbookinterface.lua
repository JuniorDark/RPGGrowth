require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/drawingutil.lua"
require "/scripts/ivrpgutil.lua"
-- engine callbacks
function init()
  --View:init()
  
  self.clickEvents = {}
  self.state = FSM:new()
  self.state:set(splashScreenState)
  self.system = celestial.currentSystem()
  self.pane = pane
  player.addCurrency("skillbookopen", 1)

  -- Initiating Level and XP
  self.xp = math.min(player.currency("experienceorb"), 500000)rb")
  self.level = player.currency("currentlevel")
  self.mastery = player.currency("masterypoint")
  -- Mastery Conversion: 10000 Experience = 1 Mastery!!

  self.classTo = 0
  self.class = player.currency("classtype")
  self.specTo = 1
  self.spec = player.currency("spectype")
  self.profTo = 0
  self.profession = player.currency("proftype")
  self.affinityTo = 0
  self.affinity = player.currency("affinitytype")

    self.challengeText = {
      {
        {"Derrote 500 inimigos Tier 4 ou superior.", 500},
        {"Derrote 350 inimigos Tier 5 ou superior.", 350},
        {"Derrote Kluex.", 1},
        {"Derrote o Erchius Horror sem levar dano.", 1}
      },
      {
        {"Derrote 400 inimigos Tier 6 ou superior.", 400},
        {"Derrote o Bone Dragon.", 1},
        {"Colete 5 Upgrade Modules. Eles são consumidos.", 5}
      },
      {
        {"Derrote 400 inimigos de Tier Vault ou superior.", 400},
        {"Derrote 2 Vault Guardians.", 2},
        {"Derrote o Coração da Ruína.", 1},
        {"Derrote o Coração da Ruína sem levar dano.", 1},
        {"-------------------------------------------------------. <- Período é a duração máxima!"}
    }
  }

  -- Loading Configs
  self.textData = root.assetJson("/ivrpgtext.config")
  self.classList = root.assetJson("/classList.config")
  self.specList = root.assetJson("/specList.config")
  self.statList = root.assetJson("/stats.config")
  self.affinityList = root.assetJson("/affinityList.config")
  self.affinityDescriptions = root.assetJson("/affinities/affinityDescriptions.config")

  updateStats()
  updateClassInfo()
  updateAffinityInfo()
  updateSpecInfo()
  updateLevel()
end

function dismissed()
  player.consumeCurrency("skillbookopen", player.currency("skillbookopen"))
end

function update(dt)
  --if not world.sendEntityMessage(player.id(), "holdingSkillBook"):result() then
  if player.currency("skillbookopen") == 2 then
    self.pane.dismiss()
  end

  if player.currency("experienceorb") ~= self.xp then
    updateLevel()
    if widget.getChecked("bookTabs.2") then
      local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or (widget.getChecked("classlayout.techicon4") and 4 or 0))) 
      if checked ~= 0 then unlockTechVisible((tostring(checked)), 2^(checked+1)) end
      updateClassWeapon()
    elseif widget.getChecked("bookTabs.3") then
      removeLayouts()
      changeToAffinities()
    elseif widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    elseif widget.getChecked("bookTabs.6") then
      changeToProfession()
    elseif widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if player.currency("classtype") ~= self.class then
    self.class = player.currency("classtype")
    updateClassInfo()
    if widget.getChecked("bookTabs.2") then
      changeToClasses()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    elseif widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    end
  end

  if player.currency("affinitytype") ~= self.affinity then
    self.affinity = player.currency("affinitytype")
    updateAffinityInfo()
    if widget.getChecked("bookTabs.3") then
      changeToAffinities()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("spectype") ~= self.spec then
    self.spec = player.currency("spectype")
    updateSpecInfo()
    unlockSpecWeapon()
    if widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if widget.getChecked("bookTabs.5") then
      changeToSpecialization()
  end

  if player.currency("masterypoint") ~= self.mastery then
    self.mastery = player.currency("masterypoint")
    if widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if status.statPositive("ivrpgmasteryunlocked") and widget.getChecked("bookTabs.7") then
    updateChallenges()
  end

  if widget.getChecked("bookTabs.8") then
    updateUpgradeTab()
  end

  updateStats()
  if widget.getChecked("bookTabs.4") then
    updateInfo()
  end
  --checkStatPoints()

  self.state:update(dt)
end

function updateBookTab()
  removeLayouts()
  if widget.getChecked("bookTabs.0") then
    changeToOverview()
  elseif widget.getChecked("bookTabs.1") then
    changeToStats()
  elseif widget.getChecked("bookTabs.2") then
    changeToClasses()
  elseif widget.getChecked("bookTabs.3") then
    changeToAffinities()
  elseif widget.getChecked("bookTabs.4") then
    changeToInfo()
  elseif widget.getChecked("bookTabs.5") then
    changeToSpecialization()
  elseif widget.getChecked("bookTabs.6") then
    changeToProfession()
  elseif widget.getChecked("bookTabs.7") then
    changeToMastery()
  elseif widget.getChecked("bookTabs.8") then
    changeToUpgrades()
  end
end

function updateClassInfo()
  if self.class > 0 then
    self.classInfo = root.assetJson("/classes/" .. self.classList[self.class] .. ".config")
  else
    self.classInfo = root.assetJson("/classes/default.config")
  end
end

function updateSpecInfo()
  if self.spec > 0 and self.class > 0 then
    self.specInfo = root.assetJson("/specs/" .. self.specList[self.class][self.spec].name .. ".config")
  else
    self.specInfo = nil
  end
end

function updateAffinityInfo()
  if self.affinity > 0 then
    self.affinityInfo = root.assetJson("/affinities/" .. self.affinityList[self.affinity] .. ".config")
  else
    self.affinityInfo = root.assetJson("/affinities/default.config")
  end
end

function updateLevel()
  self.xp = math.min(player.currency("experienceorb"), 500000)
   if self.xp < 100 then
    player.addCurrency("experienceorb", 100)
  end
  self.level = player.currency("currentlevel")
  self.newLevel = math.floor(math.sqrt(self.xp/100))
  self.newLevel = self.newLevel >= 50 and 50 or self.newLevel
  if self.newLevel > self.level then
    addStatPoints(self.newLevel, self.level)
  elseif self.newLevel < self.level then
    player.consumeCurrency("currentlevel", self.level - self.newLevel)
  end
  self.level = player.currency("currentlevel")
  widget.setText("statslayout.statpointsleft", player.currency("statpoint"))
  updateStats()
  self.toNext = 2*self.level*100+100
  updateOverview(self.toNext)
  updateBottomBar(self.toNext)
end

function startingStats()
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      player.addCurrency(k .. "point", 1)
    end
  end
end

function addStatPoints(newLevel, oldLevel)
  player.addCurrency("currentlevel", newLevel - oldLevel)
  while newLevel > oldLevel do
    if oldLevel > 48 then
      player.addCurrency("statpoint", 4)
    elseif oldLevel > 38 then
      player.addCurrency("statpoint", 3)
    elseif oldLevel > 18 then
      player.addCurrency("statpoint", 2)
    elseif oldLevel > 0 then
      player.addCurrency("statpoint", 1)
    else
      startingStats()
    end
    oldLevel = oldLevel + 1
  end
end

function updateBottomBar(toNext)
  widget.setText("levelLabel", "Nível " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("xpLabel","XP Maxima!")
    widget.setProgress("experiencebar",1)
  else
    widget.setText("xpLabel",tostring(math.floor((self.xp-self.level^2*100))) .. "/" .. tostring(toNext))
    widget.setProgress("experiencebar",(self.xp-self.level^2*100)/toNext)
  end
end

function updateOverview(toNext)
  widget.setText("overviewlayout.levellabel","Nível " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("overviewlayout.xptglabel","Experiência Necessária Para Subir de Nível: N/D.")
    widget.setText("overviewlayout.xptotallabel","Total de Orbs de Experiência Coletados: " .. tostring(self.xp))
  else
    widget.setText("overviewlayout.xptglabel","Experiência Necessária Para Subir de Nível: " .. tostring(toNext - (math.floor(self.xp-self.level^2*100))))
    widget.setText("overviewlayout.xptotallabel","Total de Orbs de Experiência Coletados: " .. tostring(self.xp))
  end
  widget.setText("overviewlayout.statpointsremaining","Pontos de Status Disponíveis: " .. tostring(player.currency("statpoint")))

  local classicText = ""
  for k,v in ipairs(self.classInfo.classic) do
    if v.type == "movement" or v.type == "status" then
      classicText = classicText .. v.text .. "\n"
    end
  end
  widget.setText("overviewlayout.hardcoretext", classicText)
  widget.setText("overviewlayout.classtitle", self.classInfo.title)
  widget.setFontColor("overviewlayout.classtitle", self.classInfo.color)
  widget.setImage("overviewlayout.classicon", self.classInfo.image)

  widget.setText("overviewlayout.affinitytitle", self.affinityInfo.title)
  widget.setFontColor("overviewlayout.affinitytitle", self.affinityInfo.color)
  widget.setImage("overviewlayout.affinityicon", self.affinityInfo.image)

  widget.setText("overviewlayout.spectitle", (self.specInfo and self.specInfo.title or ""))

  if status.statPositive("ivrpghardcore") then
    widget.setText("overviewlayout.hardcoretoggletext", "Ativo")
    widget.setVisible("overviewlayout.hardcoretext", true)
    widget.setVisible("overviewlayout.hardcoreweapontext", true)
  else
    widget.setText("overviewlayout.hardcoretoggletext", "Inativo")
    widget.setVisible("overviewlayout.hardcoretext", false)
    widget.setVisible("overviewlayout.hardcoreweapontext", false)
  end

  if not status.statusProperty("ivrpgrallymode", false) then
    widget.setText("overviewlayout.rallymodeactive", "Inativo")
  else
    widget.setText("overviewlayout.rallymodeactive", "Ativo")
  end
end

function updateClassTab()
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","Sem Classe Ainda")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon2","/objects/class/noclassicon.png")
  else
    updateClassInfo()
    local classInfo = self.classInfo
    widget.setText("classlayout.classtitle", classInfo.title)
    widget.setFontColor("classlayout.classtitle", classInfo.color)
    widget.setFontColor("classlayout.effecttext", classInfo.color)
    widget.setImage("classlayout.classicon", classInfo.image)
    widget.setText("classlayout.effecttext", classInfo.ability.text)
    widget.setImage("classlayout.effecticon", classInfo.ability.image)
    widget.setImage("classlayout.effecticon2", classInfo.ability.image)
    widget.setImage("classlayout.classweaponicon", classInfo.weapon.image)
    updateClassText()
    updateTechImages()
    updateClassWeapon()
  end
  
  if status.statPositive("ivrpgclassability") then widget.setText("classlayout.classabilitytoggletext", "Inativo")
  else widget.setText("classlayout.classabilitytoggletext", "Ativo") end

end

function updateClassText()
  --Weapon Bonus
  widget.setText("classlayout.weapontext", concatTableValues(self.classInfo.weaponBonuses, "\n"))

  --Passive
  widget.setText("classlayout.passivetext", concatTableValues(self.classInfo.passive, "\n"))

  --Scaling
  local scalingArray = {{"^green;Incrível^reset;"}, {"^blue;Ótimo^reset;"}, {"^magenta;Bom^reset;"}, {"^gray;OK^reset;"}}
  local scalingComp = {amazing = 1, great = 2, good = 3, ok = 4}
  for k,v in ipairs(self.classInfo.scaling) do
    currentIndex = scalingComp[v.textType]
    currentTable = scalingArray[currentIndex]
    table.insert(currentTable, v.text)
    scalingArray[currentIndex] = currentTable
  end
  local scalingText = ""
  for k,v in pairs(scalingArray) do
    if #v > 1 then
      for x,y in ipairs(v) do
        scalingText = scalingText .. y .. "\n"
      end
    end
  end
  widget.setText("classlayout.statscalingtext", scalingText)

end

function removeLayouts()
  widget.setVisible("overviewlayout",false)
  widget.setVisible("statslayout",false)
  widget.setVisible("classeslayout",false)
  widget.setVisible("classlayout",false)
  widget.setVisible("affinitieslayout",false)
  widget.setVisible("affinitylayout",false)
  widget.setVisible("affinitylockedlayout",false)
  widget.setVisible("infolayout",false)
  widget.setVisible("masterylayout",false)
  widget.setVisible("masterylockedlayout",false)
  widget.setVisible("professionlayout",false)
  widget.setVisible("professionslayout",false)
  widget.setVisible("professionlockedlayout",false)
  widget.setVisible("specializationlayout",false)
  widget.setVisible("specializationslayout",false)
  widget.setVisible("specializationlockedlayout",false)
  widget.setVisible("upgradelayout", false)
end

function changeToOverview()
    widget.setText("tabLabel", "Visão Geral")
    widget.setVisible("overviewlayout", true)
    updateOverview(2*self.level*100+100)
end

function changeToStats()
    updateStats()
    widget.setText("tabLabel", "Aba de Status")
    widget.setVisible("statslayout", true)
end

function changeToClasses()
    widget.setText("tabLabel", "Aba de Classes")
    if player.currency("classtype") == 0 then
      widget.setVisible("classlayout", false)
      checkClassDescription("default")
      widget.setVisible("classeslayout", true)
      updateTechText("default")
      return
    else
      widget.setVisible("classeslayout", false)
      updateClassTab()
      widget.setVisible("classlayout", true)
    end
end

function changeToAffinities()
    widget.setText("tabLabel", "Aba de Afinidades")
    if player.currency("affinitytype") == 0 then
      widget.setVisible("affinitylayout", false)
      checkAffinityDescription("default")
      if self.level >= 25 then
        widget.setVisible("affinitieslayout", true)
      else
        widget.setVisible("affinitylockedlayout", true)
      end
      return
    else
      widget.setVisible("affinitieslayout", false)
      updateAffinityTab()
      widget.setVisible("affinitylayout", true)
    end
end

function changeToInfo()
    widget.setText("tabLabel", "Aba de Informações")
    widget.setVisible("infolayout", true)
    updateInfo()
end

function changeToSpecialization()
    widget.setText("tabLabel", "Aba de Especialização")
    --self.specTo = 1
    if self.level < 35 or self.class == 0 then
      widget.setVisible("specializationlayout", false)
      widget.setVisible("specializationslayout", false)
      widget.setVisible("specializationlockedlayout", true)
    elseif self.spec == 0 then
      updateSpecializationSelect()
      widget.setVisible("specializationlockedlayout", false)
      widget.setVisible("specializationslayout", true)
      widget.setVisible("specializationlayout", false)
    else
      updateSpecializationTab()
      widget.setVisible("specializationlockedlayout", false)
      widget.setVisible("specializationslayout", false)
      widget.setVisible("specializationlayout", true)
    end
end

function changeToProfession()
    widget.setText("tabLabel", "Aba de Profissão")
    if self.level < 10 then
      widget.setVisible("professionlayout", false)
      widget.setVisible("professionlockedlayout", true)
    else
      widget.setVisible("professionlockedlayout", false)
      if player.currency("proftype") == 0 then
        widget.setVisible("professionlayout", false)
        widget.setVisible("professionslayout", true)
      else
        updateProfessionTab()
        widget.setVisible("professionslayout", false)
        widget.setVisible("professionlayout", true)
      end
    end
end

function changeToMastery()
    widget.setText("tabLabel", "Aba de Mestria")
    if self.level < 50 and not status.statPositive("ivrpgmasteryunlocked") then
      widget.setVisible("masterylayout", false)
      widget.setVisible("masterylockedlayout", true)
    else
      updateMasteryTab()
      widget.setVisible("masterylockedlayout", false)
      widget.setVisible("masterylayout", true)
      if not status.statPositive("ivrpgmasteryunlocked") then
        status.setPersistentEffects("ivrpgmasteryunlocked", {
          {stat = "ivrpgmasteryunlocked", amount = 1}
        })
      end
    end
end

function changeToUpgrades()
  widget.setText("tabLabel", "Aba de Aprimoramento")
  widget.setVisible("upgradelayout", true)
  updateUpgradeTab()
end

function updateProfessionTab()
end

function updateSpecializationSelect()
  self.availableSpecs = self.specList[self.class]
  local currentSpec = self.availableSpecs[self.specTo]

  widget.setText("specializationslayout.spectitle", currentSpec.title)
  if currentSpec.titleColor then
  	widget.setFontColor("specializationslayout.spectitle", currentSpec.titleColor)
  end

  widget.setText("specializationslayout.desctext", currentSpec.description)
  widget.setText("specializationslayout.loretext", concatTableValues(currentSpec.flavor, "\n\n"))
  widget.setText("specializationslayout.weapontext", concatTableValues(currentSpec.weaponText, "\n\n"))

  widget.setText("specializationslayout.unlocktext", currentSpec.unlockText)

  local unlockStatus = currentSpec.unlockStatus
  local unlocked = status.statusProperty(unlockStatus, false)

  if type(unlocked) == "number" and currentSpec.unlockNumber then
  	widget.setText("specializationslayout.unlocktext", currentSpec.unlockText .. " " .. math.floor(unlocked*100)/100 .. "/" .. currentSpec.unlockNumber)
  end

  if unlocked ~= true then unlocked = false end
  
  widget.setVisible("specializationslayout.unlocktext", not unlocked)
  widget.setButtonEnabled("specializationslayout.selectspec", not (currentSpec.gender and currentSpec.gender ~= player.gender()))
  widget.setVisible("specializationslayout.selectspec", unlocked)  
end

function updateSpecializationTab()
  if self.class == 0 or self.spec == 0 then return end
  self.specType = self.specList[self.class][self.spec].name
  updateSpecInfo()
  local specInfo = self.specInfo

  widget.setText("specializationlayout.spectitle", specInfo.title)
  
  widget.setText("specializationlayout.classictext", concatTableValues(specInfo.classic, "\n"))
  
  widget.setText("specializationlayout.effecttext", specInfo.ability.text)
  
  widget.setText("specializationlayout.detrimenttext", concatTableValues(specInfo.effects, "\n", "detriment"))
  widget.setText("specializationlayout.benefittext", concatTableValues(specInfo.effects, "\n", "benefit"))
  
  widget.setText("specializationlayout.specweapontitle", specInfo.weapon.title)
  
  widget.setText("specializationlayout.specweapontext", concatTableValues(specInfo.weapon.text, "\n"))
  
  widget.setText("specializationlayout.techname", specInfo.tech.title)
  widget.setText("specializationlayout.techtype", specInfo.tech.type .. " Tech")
  widget.setText("specializationlayout.techtext", specInfo.tech.text)
  
  widget.setText("specializationlayout.statscalingtext",  concatTableValues(specInfo.effects, "\n", "scaling-up") .. concatTableValues(specInfo.effects, "\n", "scaling-down"))

  widget.setImage("specializationlayout.techicon2", specInfo.tech.image)
  widget.setImage("specializationlayout.effecticon", specInfo.ability.image)
  widget.setImage("specializationlayout.effecticon2", specInfo.ability.image)
  widget.setImage("specializationlayout.specweaponicon", specInfo.weapon.image)

  local tech = specInfo.tech.name
  if hasValue(player.availableTechs(), tech) then
    widget.setVisible("specializationlayout.unlockbutton", false)
    widget.setVisible("specializationlayout.unlockedtext", true)
  else
    widget.setVisible("specializationlayout.unlockbutton", true)
    widget.setVisible("specializationlayout.unlockedtext", false)
  end
end

function unlockSpecTech()
  local specInfo = self.specInfo
  local tech = specInfo.tech.name
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  updateSpecializationTab()
end

function specRight()
  self.specTo = (self.specTo == #self.availableSpecs) and 1 or self.specTo + 1
  updateSpecializationSelect()
end

function specLeft()
  self.specTo = (self.specTo == 1) and #self.availableSpecs or self.specTo - 1
  updateSpecializationSelect()
end

function chooseSpec()
  player.addCurrency("spectype", self.specTo)
end

function unlockSpecWeapon()
  	if self.spec > 0 then
	  for _,weapon in ipairs(self.specInfo.weapon.name) do
	  	player.giveBlueprint(weapon)
	  end
	end
end

function unequipSpecialization()
	rescrollSpecialization(self.class, self.spec)
end

function concatTableValues(table, delim, required)
  local returnV = ""
  local color = true
  local colorSwitch = {}
  colorSwitch[true] = "^white;"
  colorSwitch[false] = "^#d1d1d1;"
  for k,v in ipairs(table) do
    if (required and required == v.textType) or not required then
      returnV = returnV .. (v.textColor and ("^" .. v.textColor .. ";") or colorSwitch[color]) .. (type(v) == "table" and v.text or v) .. "^reset;" .. delim
      color = not color
    end
  end
  if returnV ~= "" and required then
    returnV = (required == "scaling-up" and "^green;Aumentado^reset;\n" or (required == "scaling-down" and "^red;Diminuido^reset;\n" or "")) .. returnV
  end
  return returnV
end

function tableLength(table)
  local length = 0
  for k,v in pairs(table) do
    length = length + 1
  end
  return length
end

function updateUpgradeTab()

  local effectName = "nil"

  if status.statPositive("ivrpguctech") then
    effectName = status.getPersistentEffects("ivrpguctech")[2].stat
    widget.setText("upgradelayout.techname", self.textData.upgrades.tech[effectName].title)
    widget.setText("upgradelayout.techtext", self.textData.upgrades.tech[effectName].description)
    widget.setButtonEnabled("upgradelayout.tech", true)
  else
    widget.setText("upgradelayout.techname", "NÃO UTILIZADO")
    widget.setText("upgradelayout.techtext", "-")
    widget.setButtonEnabled("upgradelayout.tech", false)
  end

  if status.statPositive("ivrpgucweapon") then
    effectName = status.getPersistentEffects("ivrpgucweapon")[2].stat
    widget.setText("upgradelayout.weaponname", self.textData.upgrades.weapon[effectName].title)
    widget.setText("upgradelayout.weapontext", self.textData.upgrades.weapon[effectName].description)
    widget.setButtonEnabled("upgradelayout.weapon", true)
  else
    widget.setText("upgradelayout.weaponname", "NÃO UTILIZADO")
    widget.setText("upgradelayout.weapontext", "-")
    widget.setButtonEnabled("upgradelayout.weapon", false)
  end

  if status.statPositive("ivrpgucaffinity") then
    effectName = status.getPersistentEffects("ivrpgucaffinity")[2].stat
    widget.setText("upgradelayout.affinityname", self.textData.upgrades.affinity[effectName].title)
    widget.setText("upgradelayout.affinitytext", self.textData.upgrades.affinity[effectName].description)
    widget.setButtonEnabled("upgradelayout.affinity", true)
  else
    widget.setText("upgradelayout.affinityname", "NÃO UTILIZADO")
    widget.setText("upgradelayout.affinitytext", "-")
    widget.setButtonEnabled("upgradelayout.affinity", false)
  end

  if status.statPositive("ivrpgucgeneral") then
    effectName = status.getPersistentEffects("ivrpgucgeneral")[2].stat
    widget.setText("upgradelayout.generalname", self.textData.upgrades.general[effectName].title)
    widget.setText("upgradelayout.generaltext", self.textData.upgrades.general[effectName].description)
    widget.setButtonEnabled("upgradelayout.general", true)
  else
    widget.setText("upgradelayout.generalname", "NÃO UTILIZADO")
    widget.setText("upgradelayout.generaltext", "-")
    widget.setButtonEnabled("upgradelayout.general", false)
  end
end

function updateMasteryTab()
  widget.setText("masterylayout.masterypoints", self.mastery)
  widget.setText("masterylayout.xpover", math.max(0, math.min(self.xp - 250000, 250000)))

  if self.mastery < 3 or self.xp < 250000 then
    widget.setButtonEnabled("masterylayout.prestigebutton", false)
  else
    widget.setButtonEnabled("masterylayout.prestigebutton", true)
  end

  if self.mastery < 5 then
    widget.setButtonEnabled("masterylayout.shopbutton", false)
  else
    widget.setButtonEnabled("masterylayout.shopbutton", true)
  end

  if self.mastery == 100 or self.xp < 260000 then
    widget.setButtonEnabled("masterylayout.refinebutton", false)
  else
    widget.setButtonEnabled("masterylayout.refinebutton", true)
  end

  updateChallenges()
end

function updateInfo()
  self.classType = player.currency("classtype")
  self.strengthBonus = 1 + status.stat("ivrpgstrengthscaling")
  self.agilityBonus = 1 + status.stat("ivrpgagilityscaling")
  self.vitalityBonus = 1 + status.stat("ivrpgvitalityscaling")
  self.vigorBonus = 1 + status.stat("ivrpgvigorscaling")
  self.intelligenceBonus = 1 + status.stat("ivrpgintelligencescaling")
  self.enduranceBonus = 1 + status.stat("ivrpgendurancescaling")
  self.dexterityBonus = 1 + status.stat("ivrpgdexterityscaling")

  widget.setText("infolayout.displaystats", 
    "Quantidade\n" ..
    "^red;" .. math.floor(100*(1 + self.vitality^self.vitalityBonus*.05))/100 .. "^reset;" .. "\n" ..
    "^green;" .. math.floor(100*(1 + self.vigor^self.vigorBonus*.05))/100 .. "\n" ..
    math.floor(status.stat("energyRegenPercentageRate")*100+.5)/100 .. "\n" ..
    math.floor(status.stat("energyRegenBlockTime")*100+.5)/100 .. "^reset;" .. "\n" ..
    "^orange;" .. getStatPercent(status.stat("foodDelta")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("grit")) ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..
    math.floor((1 + self.strength^self.strengthBonus*.05)*100+.5)/100 .. "^reset;" .. "\n" ..
    "^red;" .. (math.floor(10000*status.stat("ivrpgBleedChance"))/100) .. "%\n" ..
    (math.floor(100*status.stat("ivrpgBleedLength"))/100) .. "^reset;" .. "\n" ..
    "\n\nPorcentagem\n" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^green;" .. getStatPercent(status.stat("poisonResistance")) .. "^reset;" ..
    "^blue;" .. getStatPercent(status.stat("iceResistance")) .. "^reset;" .. 
    "^red;" .. getStatPercent(status.stat("fireResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("electricResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("novaResistance")) .. "^reset;" .. 
    "^black;" .. getStatPercent(status.stat("demonicResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("holyResistance")) .. "^reset;" ..
    "^green;" .. getStatPercent(status.stat("radioactiveResistance")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("shadowResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("cosmicResistance")) .. "^reset;")

  widget.setText("infolayout.displaystatsFU", 
    "Imunidade\n" ..
    "^red;" .. getStatImmunity(status.stat("fireStatusImmunity")) ..
    getStatImmunity(status.stat("lavaImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeheatImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeheatImmunity")) .. "]\n" .. "^reset;" ..
    "^blue;" .. getStatImmunity(status.stat("iceStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomecoldImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremecoldImmunity")) .. "]\n" .. 
    getStatImmunity(status.stat("breathProtection")) .. "^reset;" ..
    "^green;" .. getStatImmunity(status.stat("poisonStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeradiationImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeradiationImmunity")) .. "]\n" .. "^reset;" ..
    "^yellow;" .. getStatImmunity(status.stat("electricStatusImmunity")) .. "^reset;" ..
    "^gray;" .. getStatImmunity(status.stat("invulnerable")))

  if status.statPositive("ivrpghardcore") then
    widget.setText("infolayout.displayWeapons", concatTableValues(self.classInfo.classic, "\n"))
    widget.setVisible("infolayout.displayWeapons", true)
  else
    widget.setVisible("infolayout.displayWeapons", false)
  end
end

function unlockTech()
  local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or 4))
  local tech = self.classInfo.techs[checked].name
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  unlockTechVisible((tostring(checked)), 2^(checked+1))
end

function hasValue(table, value)
  for index, val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

function unlockTechVisible(tech, amount)
  local check = player.currency("experienceorb") >= amount^2*100
  if check then
    local techName = self.classInfo.techs[tonumber(tech)].name
    if hasValue(player.availableTechs(), techName) then
      widget.setButtonEnabled("classlayout.unlockbutton", false)
      widget.setVisible("classlayout.unlockedtext", true)
    else
      widget.setButtonEnabled("classlayout.unlockbutton", true)
    end
    widget.setVisible("classlayout.reqlvl", false)
  else
    widget.setButtonEnabled("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.reqlvl", true)
    widget.setText("classlayout.reqlvl", "Nível Requerido: " .. math.floor(amount))
  end
  widget.setVisible("classlayout.unlockbutton", true)
end

function updateTechText(name)
  name = string.gsub(name,"techicon","")
  uncheckTechButtons(name)
  if not widget.getChecked("classlayout.techicon1") and not widget.getChecked("classlayout.techicon2") and not widget.getChecked("classlayout.techicon3") and not widget.getChecked("classlayout.techicon4") then
    widget.setText("classlayout.techtext", "Selecione uma habilidade para ler sobre ela e desbloqueie-a, se possível.")
    widget.setVisible("classlayout.techname", false)
    widget.setVisible("classlayout.techtype", false)
    widget.setVisible("classlayout.reqlvl", false)
    widget.setVisible("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.unlockedtext", false)
    return
  else
    widget.setVisible("classlayout.techname", true)
    widget.setVisible("classlayout.techtype", true)
  end

  for i=1,4 do
    if name == tostring(i) then
      local tech = self.classInfo.techs[i]
      widget.setText("classlayout.techtext", tech.text)
      widget.setText("classlayout.techname", tech.title)
      widget.setText("classlayout.techtype", tech.type .. " Tech")
      unlockTechVisible(name, tech.level)
    end
  end
end

function uncheckTechButtons(name)
  widget.setVisible("classlayout.reqlvl", false)
  widget.setVisible("classlayout.unlockbutton", false)
  widget.setVisible("classlayout.unlockedtext", false)
  for i=1,4 do
    if name ~= tostring(i) then widget.setChecked("classlayout.techicon" .. i, false) end
  end
end

function updateTechImages()
  local className = self.classInfo.name
  for i=1,4 do
    widget.setButtonImages("classlayout.techicon" .. i, {
      base = "/interface/RPGskillbook/techbuttons/" .. className .. i .. ".png",
      hover = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "hover.png",
      pressed = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "pressed.png",
      disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
    })
    widget.setButtonCheckedImages("classlayout.techicon" .. i, {
      base = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "pressed.png",
      hover = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "hover.png"
    })
  end
end

function getStatPercent(stat)
  stat = math.floor(stat*10000+.50)/100
  return stat >= 100 and "Imune!\n" or (stat < 0 and stat .. "%\n" or (stat == 0 and "0%\n" or "+" .. stat .. "%\n"))
end

function getStatMultiplier(stat)
  stat = math.floor(stat*100+.5)/100
  return stat <= 0 and "0\n" or (stat .. "\n")
end

function getStatImmunity(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper) .. "\n"
end

function getStatImmunityNoLine(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper)
end

function raiseStat(name)
  player.consumeCurrency("statpoint", 1)
  name = string.gsub(name,"raise","") .. "point"
  player.addCurrency(name, 1)
  updateStats()
end

function checkStatPoints()
  if player.currency("statpoint") == 0 then
    enableStatButtons(false)
  elseif player.currency("statpoint") ~= 0 then
    enableStatButtons(true)
  end
end

function checkStatDescription(name)
  name = string.gsub(name,"icon","")
  uncheckStatIcons(name)
  if (widget.getChecked("statslayout."..name.."icon")) then
    changeStatDescription(name)
  else
    changeStatDescription("default")
  end
end

function checkClassDescription(name)
  name = string.gsub(name,"icon","")
  uncheckClassIcons(name)
  if (widget.getChecked("classeslayout."..name.."icon")) then
    changeClassDescription(name)
    widget.setButtonEnabled("classeslayout.selectclass", true)
  else
    changeClassDescription("default")
    widget.setButtonEnabled("classeslayout.selectclass", false)
  end
end

function updateStats()
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      self[k] = player.currency(k .. "point")
      widget.setText("statslayout." .. k .. "amount", self[k])
    else
      self[k] = 0
    end
  end
  widget.setText("statslayout.statpointsleft", player.currency("statpoint"))
  widget.setText("statslayout.totalstatsamount", addStats())
  checkStatPoints()
end

function addStats()
  return self.strength + self.agility + self.vitality + self.vigor + self.intelligence + self.endurance + self.dexterity
end

function uncheckStatIcons(name)
  for k,v in pairs(self.statList) do
    if name ~= k then
      widget.setChecked("statslayout." .. k .. "icon", false)
    end
  end
end

function uncheckClassIcons(name)
  for k,v in ipairs(self.classList) do
    if name ~= v and v ~= "default" then
      widget.setChecked("classeslayout." .. v .. "icon", false)
      widget.setFontColor("classeslayout." .. v .. "title", "white")
    end
  end
end

function changeStatDescription(name)
  widget.setText("statslayout.statdescription", concatTableValues(self.statList[name], "\n"))
end

function changeClassDescription(name)
  local textArray = root.assetJson("/classes/classDescriptions.config")[name]
  widget.setText("classeslayout.classdescription", textArray.text) 
  widget.setFontColor("classeslayout." .. name .. "title", textArray.color)
  self.classTo = textArray.class
  uncheckClassIcons(name)
end

function enableStatButtons(enable)
  if player.currency("classtype") == 0 then
    enable = false
    widget.setVisible("statslayout.statprevention",true)
  else
    widget.setVisible("statslayout.statprevention",false)
  end
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      widget.setButtonEnabled("statslayout.raise" .. k, self[k] ~= 50 and enable)
    end
  end
end

function chooseClass()
  player.addCurrency("classtype", self.classTo)
  self.class = self.classTo
  updateClassInfo()
  addClassStats()
  changeToClasses()
end

function addClassStats()
  for k,v in pairs(self.classInfo.stats) do
    player.addCurrency(k .. "point", v)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

function areYouSure(name)
  name = string.gsub(name,"resetbutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  widget.setVisible(name2..".resetbutton"..name, false)
  widget.setVisible(name2..".yesbutton", true)
  widget.setVisible(name2..".nobutton"..name, true)
  widget.setVisible(name2..".areyousure", true)
  --widget.setVisible(name2..".hardcoretext", false)
end

function notSure(name)
  name = string.gsub(name,"nobutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  widget.setVisible(name2..".resetbutton"..name, true)
  widget.setVisible(name2..".yesbutton", false)
  widget.setVisible(name2..".nobutton"..name, false)
  widget.setVisible(name2..".areyousure", false)
  --updateOverview(2*self.level*100+100)
end

function resetSkillBook()
  notSure("nobutton")
  consumeAllRPGCurrency()
  consumeMasteryCurrency()
  removeTechs()
end

function removeTechs()
  for k,v in ipairs(self.classInfo.techs) do
    player.makeTechUnavailable(v.name)
  end
end

function updateClassWeapon()
  if self.class == 0 then return end
  if player.hasCompletedQuest(self.classInfo.weapon.quest) then
    widget.setText("classlayout.classweapontext", concatTableValues(self.classInfo.weapon.text, "\n"))
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", true)
  elseif self.level < 12 then
    widget.setFontColor("classlayout.weaponreqlvl", "red")
    widget.setText("classlayout.weaponreqlvl", "Nível Requerido: 12")
    widget.setVisible("classlayout.weaponreqlvl", true)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", false)
  elseif player.hasQuest(self.classInfo.weapon.quest) then
    widget.setText("classlayout.classweapontext", "Complete a primeira missão para mais informações.")
    widget.setVisible("classlayout.classweapontext", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
  else
    widget.setVisible("classlayout.unlockquestbutton", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.classweapontext", false)
  end
end

function unlockQuest()
  player.startQuest(self.classInfo.weapon.quest)
  widget.setVisible("classlayout.unlockquestbutton", false)
  widget.setText("classlayout.classweapontext", "Complete a primeira missão para mais informações.")
  widget.setVisible("classlayout.classweapontext", true)
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
  updateAffinityInfo()
  addAffinityStats()
  changeToAffinities()
end

function upgradeAffinity()
  player.addCurrency("affinitytype", 4)
  self.affinity = self.affinity + 4
  addAffinityStats()
  changeToAffinities()
end

function checkAffinityDescription(name)
  name = string.gsub(name,"icon","")
  uncheckAffinityIcons(name)
  if (widget.getChecked("affinitieslayout."..name.."icon")) then
    changeAffinityDescription(name)
    widget.setButtonEnabled("affinitieslayout.selectaffinity", true)
  else
    changeAffinityDescription("default")
    widget.setButtonEnabled("affinitieslayout.selectaffinity", false)
  end
end

function uncheckAffinityIcons(name)
  for k,v in pairs(self.affinityDescriptions) do
    if name ~= k and k ~= "default" then
      widget.setChecked("affinitieslayout." .. k .. "icon", false)
      widget.setFontColor("affinitieslayout." .. k .. "title", "white")
    end
  end
end

function changeAffinityDescription(name)
  local affinity = self.affinityDescriptions[name]
  widget.setText("affinitieslayout.affinitydescription", affinity.text) 
  widget.setFontColor("affinitieslayout." .. name .. "title", affinity.color)
  self.affinityTo = affinity.type
  uncheckAffinityIcons(name)
end

function updateAffinityTab()
  updateAffinityInfo()
  widget.setText("affinitylayout.affinitytitle", self.affinityInfo.title)
  widget.setFontColor("affinitylayout.affinitytitle", self.affinityInfo.color)
  widget.setImage("affinitylayout.affinityicon", self.affinityInfo.image)
  widget.setText("affinitylayout.passivetext", concatTableValues(self.affinityInfo.passive, "\n"))
  widget.setText("affinitylayout.immunitytext", concatTableValues(self.affinityInfo.immunity, "\n"))
  widget.setText("affinitylayout.weaknesstext", concatTableValues(self.affinityInfo.weakness, "\n"))
  widget.setText("affinitylayout.upgradetext", concatTableValues(self.affinityInfo.upgrade, "\n"))
  local statText = ""
  for k,v in pairs(self.affinityInfo.stats) do
    statText = statText .. "+" .. v .. " " .. k:gsub("^%l", string.upper) .. "\n"
  end
  widget.setText("affinitylayout.statscalingtext", statText)
  
  if self.affinity > 4 then
    widget.setVisible("affinitylayout.effecttext", false)
  elseif self.affinity > 0 then
    widget.setVisible("affinitylayout.effecttext", true)
  end

  if status.statPositive("ivrpgaesthetics") then
    widget.setText("affinitylayout.aestheticstoggletext", "Ativo")
  else
    widget.setText("affinitylayout.aestheticstoggletext", "Inativo")
  end
end

function addAffinityStats()
  for k,v in pairs(self.affinityInfo.stats) do
    addAffintyStatsHelper(k .. "point", v)
  end
  updateStats()
  uncheckAffinityIcons("default")
  changeAffinityDescription("default")
end

function addAffintyStatsHelper(statName, amount)
  local current = 50 - player.currency(statName)
  if current < amount then
    --Adds Stat Points if Bonus Stat is near maxed!
    player.addCurrency("statpoint", amount - current)
  end
  player.addCurrency(statName, amount)
end

function toggleAesthetics()
  if status.statPositive("ivrpgaesthetics") then
    status.clearPersistentEffects("ivrpgAesthetics")
  else
    status.setPersistentEffects("ivrpgAesthetics",
    {
      {stat = "ivrpgaesthetics", amount = 1}
    })
  end
  updateAffinityTab()
end

function toggleHardcore()
  if status.statPositive("ivrpghardcore") then
    status.clearPersistentEffects("ivrpgHardcore")
  else
    status.setPersistentEffects("ivrpgHardcore",
    {
      {stat = "ivrpghardcore", amount = 1}
    })
  end
  updateOverview(2*self.level*100+100)
end

function toggleRallyMode()
  if not status.statusProperty("ivrpgrallymode", false) then
													
	  
  	status.setStatusProperty("ivrpgrallymode", true)
  else
  	status.setStatusProperty("ivrpgrallymode", false)
  end
  updateOverview(2*self.level*100+100)
end

function toggleClassAbility()
  if status.statPositive("ivrpgclassability") then
    status.clearPersistentEffects("ivrpgClassAbility")
  else
    status.setPersistentEffects("ivrpgClassAbility",
    {
      {stat = "ivrpgclassability", amount = 1}
    })
  end
  updateClassTab()
end

function consumeAllRPGCurrency()
  player.consumeCurrency("experienceorb", player.currency("experienceorb") - 100)
  player.consumeCurrency("currentlevel", self.level - 1)
  player.consumeCurrency("statpoint", player.currency("statpoint"))
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      player.consumeCurrency(k .. "point", player.currency(k .. "point"))
    end
  end
  rescrollSpecialization(self.class, self.spec)
  player.consumeCurrency("classtype",player.currency("classtype"))
  player.consumeCurrency("affinitytype",player.currency("affinitytype"))
  player.consumeCurrency("proftype",player.currency("proftype"))
  player.consumeCurrency("spectype",player.currency("spectype"))
  startingStats()
  updateStats()
end

function prestige()
  player.consumeCurrency("masterypoint", 3)
  consumeAllRPGCurrency()
end

function purchaseShop()
  player.consumeCurrency("masterypoint", 5)
  player.giveItem("ivrpgmasteryshop")
end

function refine()
  local xp = math.min(self.xp, 500000) - 250000
  local mastery = math.floor(xp/10000)
  player.addCurrency("masterypoint", mastery)
  player.consumeCurrency("experienceorb", 10000*mastery)
end

function updateChallenges()
  if not status.statPositive("ivrpgchallenge1") then
    status.setPersistentEffects("ivrpgchallenge1", {
    -- 1. Defeat 150 Level 4 or higher enemies.
    -- 2. Defeat 100 Level 6 or higher enemies.
    -- 3. Defeat 1 Boss Monster.
    -- 4. Defeat the Erchius Horror without taking damage.
      {stat = "ivrpgchallenge1", amount = math.random(1,3)}
    })
  end
  if not status.statPositive("ivrpgchallenge2") then
    -- 1. Defeat 300 Level 6 or higher enemies.
    -- 2. Defeat 3 Boss Monsters.
    status.setPersistentEffects("ivrpgchallenge2", {
      {stat = "ivrpgchallenge2", amount = math.random(1,2)}
    })
  end
  if not status.statPositive("ivrpgchallenge3") then
    -- 1. Defeat 300 Vault enemies.
    -- 2. Defeat 3 Vault Guardians.
    -- 3. Defeat 5 Boss Monsters.
    -- 4. Deafeat the Heart of Ruin without taking damage.
    status.setPersistentEffects("ivrpgchallenge3", {
      {stat = "ivrpgchallenge3", amount = math.random(1,3)}
    })
  end
  updateChallengesText()
end

function updateChallengesText()
  local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

  widget.setText("masterylayout.challenge1", self.challengeText[1][challenge1][1])
  widget.setText("masterylayout.challenge2", self.challengeText[2][challenge2][1])
  widget.setText("masterylayout.challenge3", self.challengeText[3][challenge3][1])

  local prog1 = math.floor(status.statusProperty("ivrpgchallenge1progress", 0))
  local prog2 = math.floor(status.statusProperty("ivrpgchallenge2progress", 0))
  local prog3 = math.floor(status.statusProperty("ivrpgchallenge3progress", 0))

  local maxprog1 = self.challengeText[1][challenge1][2]
  local maxprog2 = self.challengeText[2][challenge2][2]
  local maxprog3 = self.challengeText[3][challenge3][2]

  widget.setText("masterylayout.challenge1progress", (prog1 > maxprog1 and maxprog1 or prog1) .. " / " .. maxprog1)
  widget.setText("masterylayout.challenge2progress", (prog2 > maxprog2 and maxprog2 or prog2) .. " / " .. maxprog2)
  widget.setText("masterylayout.challenge3progress", (prog3 > maxprog3 and maxprog3 or prog3) .. " / " .. maxprog3)

  if prog1 >= maxprog1 then
    widget.setFontColor("masterylayout.challenge1progress", "green")
    widget.setButtonEnabled("masterylayout.challenge1button", true)
  else
    widget.setFontColor("masterylayout.challenge1progress", "red")
    widget.setButtonEnabled("masterylayout.challenge1button", false)
  end

  if prog2 >= maxprog2 then
    widget.setFontColor("masterylayout.challenge2progress", "green")
    widget.setButtonEnabled("masterylayout.challenge2button", true)
  else
    widget.setFontColor("masterylayout.challenge2progress", "red")
    widget.setButtonEnabled("masterylayout.challenge2button", false)
  end

  if prog3 >= maxprog3 then
    widget.setFontColor("masterylayout.challenge3progress", "green")
    widget.setButtonEnabled("masterylayout.challenge3button", true)
  else
    widget.setFontColor("masterylayout.challenge3progress", "red")
    widget.setButtonEnabled("masterylayout.challenge3button", false)
  end

end

function challengeRewards(name)
  local rand = math.random(1,10)
  if name == "challenge1button" then
    status.clearPersistentEffects("ivrpgchallenge1")
    status.setStatusProperty("ivrpgchallenge1progress", 0)
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(1000,2000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(500,1000)})
      player.giveItem({"experienceorb", math.random(250,500)})
    elseif rand < 9 then
      player.giveItem({"liquidfuel", 500})
      player.giveItem({"experienceorb", math.random(250,500)})
    else
      player.giveItem({"rewardbag", 5})
      player.giveItem({"experienceorb", math.random(250,500)})
    end
  elseif name == "challenge2button" then
    status.clearPersistentEffects("ivrpgchallenge2")
    status.setStatusProperty("ivrpgchallenge2progress", 0)
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(2500,5000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(1500,2500)})
      player.giveItem({"experienceorb", math.random(500,750)})
    elseif rand < 8 then
      player.giveItem({"masterypoint", 1})
    else
      player.giveItem({"ultimatejuice", math.random(5,10)})
      player.giveItem({"experienceorb", math.random(500,750)})
    end
  elseif name == "challenge3button" then
    status.clearPersistentEffects("ivrpgchallenge3")
    status.setStatusProperty("ivrpgchallenge3progress", 0)
    if rand < 5 then
      player.giveItem({"essence", math.random(500,750)})
    elseif rand < 7 then
      player.giveItem({"masterypoint", 1})
    elseif rand < 10 then
      player.giveItem({"essence", math.random(100,250)})
      player.giveItem({"diamond", math.random(7,12)})
    else
      player.giveItem({"vaultkey", 1})
    end
  end
end

function consumeMasteryCurrency()
  player.consumeCurrency("masterypoint",player.currency("masterypoint"))
  status.clearPersistentEffects("ivrpgmasteryunlocked")
  status.clearPersistentEffects("ivrpgchallenge1")
  status.clearPersistentEffects("ivrpgchallenge2")
  status.clearPersistentEffects("ivrpgchallenge3")
  status.setStatusProperty("ivrpgchallenge1progress", 0)
  status.setStatusProperty("ivrpgchallenge2progress", 0)
  status.setStatusProperty("ivrpgchallenge3progress", 0)
end

function unequipUpgrade(name)
  name = "ivrpguc" .. name
  local effects = status.getPersistentEffects(name)
  local uc = effects[2].stat or "masterypoint"
  player.giveItem(uc)
  status.setPersistentEffects(name, {
    {stat = name, amount = 0}
  })
end