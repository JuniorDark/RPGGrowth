require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/drawingutil.lua"
-- engine callbacks
function init()
  --View:init()
  
  self.clickEvents = {}
  self.state = FSM:new()
  self.state:set(splashScreenState)
  self.system = celestial.currentSystem()
  self.pane = pane
  player.addCurrency("skillbookopen", 1)
  --initiating level and xp
  self.xp = player.currency("experienceorb")
  self.level = player.currency("currentlevel")
  self.mastery = player.currency("masterypoint")
  --Mastery Conversion: 10000 Experience = 1 Mastery!!
  --initiating stats
  updateStats()
  self.classTo = 0
  self.class = player.currency("classtype")
    --[[
    0: No Class
    1: Knight
    2: Feiticeiro
    3: Ninja
    4: Soldado
    5: Ladino
    6: Explorador
    ]]
  self.specTo = 0
  self.spec = player.currency("spectype")
    --[[
    ]]
  self.profTo = 0
  self.profession = player.currency("proftype")
    --[[
    ]]
  self.affinityTo = 0
  self.affinity = player.currency("affinitytype")
  --[[
    0: No Affinity
    1: Flame
    2: Venom
    3: Frost
    4: Shock
    5: Infernal
    6: Toxic
    7: Cryo 
    8: Arc
    ]]
    self.quests = {"ivrpgaegisquest", "ivrpgnovaquest", "ivrpgaetherquest", "ivrpgversaquest", "ivrpgsiphonquest", "ivrpgspiraquest"}
    self.classWeaponText = {
      "A Aegis é uma espada que pode ser usada como um escudo. Bloqueio Perfeito ativa a habilidade de classe do Cavaleiro. Bloqueio Perfeito com o Vital Aegis restaura vida.\nAnimações de ataque por ^blue;Ribs^reset;. Confira o ^blue;Project Blade Dance^reset; se você já não tiver!",
      "A Nova é um cajado que pode trocar de elementos. O cajado troca entre Nova, Fogo, Eletricidade, e Gelo. Nova enfraquece os inimigos para Fogo, Eletricidade e Gelo. Inimigos mortos pelo Primed Nova explodem.", 
      "O Aether é uma shuriken que nunca se esgota e sempre causa sangramento. O Blood Aether rastreia inimigos e atravessa paredes e inimigos. O rastreamento escala com Destreza, e seu tempo de vida aumenta com Agilidade.", 
      "A Versa é uma arma que pode disparar em dois modos. Impacto Versa e tiro de espingarda Ricocheteante pode ser mantida para aumentar o dano e esmagar os inimigos. As balas Ricocheteantes da Versa quicam e aumenta o poder toda vez que elas ricocheteiam.", 
      "A Siphon é uma garra que usa energia para causar danos maciços para o seu finalizador. Finalizadores: Critical Slice causa sangramento e enche a fome. Venom Slice causa envenenamento e enche a vida. Lightning Slice causa energia estática e enche a energia.", 
      "A Spira é uma broca de uma mão com maior velocidade e uso infinito. Hungry Spira atrai itens pra perto. Pressionando Shift enquanto estiver usando Ravenous Spira faz com que nenhum bloco caia, mas enche a energia enquanto os quebra."
    }
    --initiating possible Level Change (thus, level currency should not be used in another script!!!)
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

    self.hardcoreWeaponText = {
      "Atualmente Pode Equipar Todas as Armas.",
      "O Cavaleiro pode equipar:^green;\nArmas Corpo-a-corpo de Duas Mãos\nArmas Corpo-a-corpo de Uma Mão ^reset;^red;\n(Não Incluindo Armas de Punho ou Chicotes)\n\nO Cavaleiro não pode usar armas duplas.",
      "O Feiticeiro pode equipar:^green;\nCajados\nVarinhas\nAdagas ^red;(Apenas na Mão Secundária)^reset;\n^green;Erchius Eye, Evil Eye, e Magnorbs.\n\nO Feiticeiro pode usar armas duplas.^reset;",
      "O Ninja pode equipar:^green;\nArmas Corpo-a-corpo de Uma Mão\nArmas de Punho e Chicotes\nAdaptable Crossbow e Solus Katana\n\nO Ninja pode usar armas duplas.^reset;",
      "O Soldado pode equipar:^green;\nArmas de Longo Alcance de Duas Mãos .\nArmas de Longo Alcance de Uma Mão.\n\n^reset;^red;O Soldado não pode usar armas duplas.\nO Soldado não pode usar Varinhas.\nO Soldado não pode usar o Erchius Eye.^reset;",
      "O Ladino pode equipar:^green;\nArmas Corpo-a-corpo de Uma Mão.\nArmas de Longo Alcance de Uma Mão.\nArmas de Punho e Chicotes\n\nO Ladino pode usar armas duplas.\n^reset;^red;O Ladino não pode usar Varinhas.^reset;",
      "O Explorador pode equipar:^green;\nQualquer Tipo de Arma\n\nO Explorador pode empunhar armas duplas.^reset;"
    }

    self.textData = root.assetJson("/ivrpgtext.config")
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
      if checked ~= 0 then unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1)) end
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
    if widget.getChecked("bookTabs.2") then
      changeToClasses()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("affinitytype") ~= self.affinity then
    self.affinity = player.currency("affinitytype")
    if widget.getChecked("bookTabs.3") then
      changeToAffinities()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
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

function updateLevel()
  self.xp = player.currency("experienceorb")
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
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
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

  if player.currency("classtype") == 0 then
    widget.setText("overviewlayout.classtitle","Sem Classe")
    widget.setImage("overviewlayout.classicon","/objects/class/noclass.png")
    widget.setText("overviewlayout.hardcoretext","Sem Efeitos Negativos")
  elseif player.currency("classtype") == 1 then
    widget.setText("overviewlayout.classtitle","Cavaleiro")
    widget.setImage("overviewlayout.classicon","/objects/class/knight.png")
    widget.setText("overviewlayout.hardcoretext","-10% Velocidade\n-30% Altura no Pulo\n-25% Energia Maxima")
  elseif player.currency("classtype") == 2 then
    widget.setText("overviewlayout.classtitle","Feiticeiro")
    widget.setImage("overviewlayout.classicon","/objects/class/wizard.png")
    widget.setText("overviewlayout.hardcoretext","-20% Velocidade\n-20% Altura no Pulo\n-20% Resistência Física")
  elseif player.currency("classtype") == 3 then
    widget.setText("overviewlayout.classtitle","Ninja")
    widget.setImage("overviewlayout.classicon","/objects/class/ninja.png")
    widget.setText("overviewlayout.hardcoretext","-50% Vida Maxima")
  elseif player.currency("classtype") == 4 then
    widget.setText("overviewlayout.classtitle","Soldado")
    widget.setImage("overviewlayout.classicon","/objects/class/soldier.png")
    widget.setText("overviewlayout.hardcoretext","-10% Altura no Pulo\n-20% Resistência a Status")
  elseif player.currency("classtype") == 5 then
    widget.setText("overviewlayout.classtitle","Ladino")
    widget.setImage("overviewlayout.classicon","/objects/class/rogue.png")
    widget.setText("overviewlayout.hardcoretext","+20% Taxa de Fome\n-20% Vida Maxima")
  elseif player.currency("classtype") == 6 then
    widget.setText("overviewlayout.classtitle","Explorador")
    widget.setImage("overviewlayout.classicon","/objects/class/explorer.png")
    widget.setText("overviewlayout.hardcoretext","-25% Multiplicador de Poder")
  end

  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("overviewlayout.affinitytitle","Sem Afinidade")
    widget.setImage("overviewlayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("overviewlayout.affinitytitle","Fogo")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 2 then
    widget.setText("overviewlayout.affinitytitle","Veneno")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 3 then
    widget.setText("overviewlayout.affinitytitle","Gelo")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 4 then
    widget.setText("overviewlayout.affinitytitle","Eletricidade")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  elseif affinity == 5 then
    widget.setText("overviewlayout.affinitytitle","Infernal")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 6 then
    widget.setText("overviewlayout.affinitytitle","Tóxico")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 7 then
    widget.setText("overviewlayout.affinitytitle","Crio")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 8 then
    widget.setText("overviewlayout.affinitytitle","Arc")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  end

  if status.statPositive("ivrpghardcore") then
    widget.setText("overviewlayout.hardcoretoggletext", "Ativo")
    widget.setVisible("overviewlayout.hardcoretext", true)
    widget.setVisible("overviewlayout.hardcoreweapontext", true)
  else
    widget.setText("overviewlayout.hardcoretoggletext", "Inativo")
    widget.setVisible("overviewlayout.hardcoretext", false)
    widget.setVisible("overviewlayout.hardcoreweapontext", false)
  end

end

function updateClassTab()
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","Sem Classe Ainda")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon2","/objects/class/noclassicon.png")
  elseif player.currency("classtype") == 1 then
    widget.setText("classlayout.classtitle","Cavaleiro")
    widget.setFontColor("classlayout.classtitle","blue")
    widget.setImage("classlayout.classicon","/objects/class/knight.png")
    widget.setText("classlayout.weapontext","+20% Dano ao usar Espada Curta e Escudo em combinação. +20% Dano com Espadas.")
    widget.setText("classlayout.passivetext","+20% Resistência a Knockback.")
    widget.setFontColor("classlayout.effecttext","blue")
    widget.setText("classlayout.effecttext","Bloqueios Perfeitos aumenta o Dano em 20% por um curto período.")
    widget.setImage("classlayout.effecticon","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.effecticon2","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/knight.png")
    widget.setText("classlayout.statscalingtext","^green;Ótimo:^reset;\nForça\n^blue;Bom:^reset;\nResistência\nVitalidade")
  elseif player.currency("classtype") == 2 then
    widget.setText("classlayout.classtitle","Feiticeiro")
    widget.setFontColor("classlayout.classtitle","magenta")
    widget.setImage("classlayout.classicon","/objects/class/wizard.png")
    widget.setFontColor("classlayout.effecttext","magenta")
    widget.setText("classlayout.weapontext","+10% Dano quando utilizando uma Varinha em qualquer mão sem estar com outra arma equipada. +10% Dano com Cajados.")
    widget.setText("classlayout.passivetext","+6% Chance de Congelar, Queimar ou Eletrificar monstros ao acertar. Esses efeitos podem acumular.")
    widget.setText("classlayout.effecttext","Ao usar Varinhas ou Cajados, ganha +10% de Resistência a Fogo, Veneno, e Gelo.")
    widget.setImage("classlayout.effecticon","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.effecticon2","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/wizard.png")
    widget.setText("classlayout.statscalingtext","^green;Incrível:^reset;\nInteligência\n^magenta;Bom:^reset;\nVigor")
  elseif player.currency("classtype") == 3 then
    widget.setText("classlayout.classtitle","Ninja")
    widget.setImage("classlayout.classicon","/objects/class/ninja.png")
    widget.setFontColor("classlayout.classtitle","red")
    widget.setFontColor("classlayout.effecttext","red")
    widget.setText("classlayout.weapontext","+20% Dano quando utilizando Estrelas de Arremesso, Facas, Kunai, ou Adagas, ou qualquer tipo de Shuriken sem qualquer arma equipada.")
    widget.setText("classlayout.passivetext","+10% Velocidade e Altura no Pulo. -10% Dano de Queda.")
    widget.setText("classlayout.effecttext","+10% Chance de Sangramento e 0.4s Duração do Sangramento durante a noite ou quando no subterrâneo.")
    widget.setImage("classlayout.effecticon","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.effecticon2","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/ninja.png")
    widget.setText("classlayout.statscalingtext","^green;Incrível:^reset;\nDestreza\n^magenta;Bom:^reset;\nAgilidade")
  elseif player.currency("classtype") == 4 then
    widget.setText("classlayout.classtitle","Soldado")
    widget.setFontColor("classlayout.classtitle","orange")
    widget.setFontColor("classlayout.effecttext","orange")
    widget.setImage("classlayout.classicon","/objects/class/soldier.png")
    widget.setText("classlayout.weapontext","+20% Dano quando utilizando Armas de Fogo de Uma Mão em combinação com Granadas. +10% Dano com Rifles Sniper, Rifles de Assalto, e Espingardas.")
    widget.setText("classlayout.passivetext","+10% Chance de Atordoar monstros ao acertar. Duração do Atordoamento depende do dano causado.")
    widget.setText("classlayout.effecttext","+10% Poder quando a Energia está cheia.\nCancelado quando a Energia cai abaixo de 75%.")
    widget.setImage("classlayout.effecticon","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.effecticon2","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/soldier.png")
    widget.setText("classlayout.statscalingtext","^blue;Ótimo:^reset;\nVigor\n^magenta;Bom:^reset;\nDestreza\n^gray;OK:^reset;\nVitalidade\nResistência")
  elseif player.currency("classtype") == 5 then
    widget.setText("classlayout.classtitle","Ladino")
    widget.setFontColor("classlayout.classtitle","green")
    widget.setFontColor("classlayout.effecttext","green")
    widget.setImage("classlayout.classicon","/objects/class/rogue.png")
    widget.setText("classlayout.weapontext","+20% Dano enquanto empunhando 2 Armas de Uma Mão.")
    widget.setText("classlayout.passivetext","+20% Chance de Envenenar monstros ao acertar.")
    widget.setText("classlayout.effecttext","Enquanto o seu Medidor de Comida estiver cheio pelo menos pela metade, ganha +20% de Resistência a Veneno.")
    widget.setImage("classlayout.effecticon","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.effecticon2","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/rogue.png")
    widget.setText("classlayout.statscalingtext","^blue;Ótimo:^reset;\nDestreza\n^magenta;Bom:^reset;\nVigor\nAgilidade")
  elseif player.currency("classtype") == 6 then
    widget.setText("classlayout.classtitle","Explorador")
    widget.setImage("classlayout.classicon","/objects/class/explorer.png")
    widget.setFontColor("classlayout.classtitle","yellow")
    widget.setFontColor("classlayout.effecttext","yellow")
    widget.setText("classlayout.weapontext","+10% de Dano e Resistência ao usar Grappling Hooks, Cordas, Ferramentas de Mineração, Fontes de Luz Arremessáveis, ou Lanternas.")
    widget.setText("classlayout.passivetext","+10% Resistência Física.")
    widget.setText("classlayout.effecttext","Enquanto a Vida é maior do que a metade, Fornece um Brilho amarelo brilhante.")
    widget.setImage("classlayout.effecticon","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.effecticon2","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/explorer.png")
    widget.setText("classlayout.statscalingtext","^blue;Ótimo:^reset;\nVitalidade\n^magenta;Bom:^reset;\nAgilidade\n^gray;OK:^reset;\nVigor\nResistência")
  end

  if status.statPositive("ivrpgclassability") then
    widget.setText("classlayout.classabilitytoggletext", "Inativo")
  else
    widget.setText("classlayout.classabilitytoggletext", "Ativo")
  end

  updateClassWeapon()
  updateTechImages()
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
    if self.level < 40 then
      widget.setVisible("specializationlayout", false)
      widget.setVisible("specializationlockedlayout", true)
    else
      updateSpecializationTab()
      widget.setVisible("specializationlockedlayout", false)
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
  widget.setText("tabLabel", "Aba de Melhoria")
  widget.setVisible("upgradelayout", true)
  updateUpgradeTab()
end

function updateProfessionTab()
end

function updateSpecializationTab()
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
  widget.setText("masterylayout.xpover", math.max(0, self.xp - 250000))

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
  --Yea, yea, this should be in its own file that all lua files can import, but I'm lazy, ya' hear?
  self.strengthBonus = self.classType == 1 and 1.15 or 1
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.05 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.15 or 1))
  self.vigorBonus = self.classType == 4 and 1.15 or (self.classType == 2 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.05 or 1)))
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

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
    "^red;" .. (math.floor(self.dexterity^self.dexterityBonus*100+.5)/200 + status.stat("ninjaBleed")) .. "%\n" ..
    (math.floor(self.dexterity^self.dexterityBonus*100+.5)/100 + status.stat("ninjaBleed"))/50 .. "^reset;" .. "\n" ..
    "\n\nPorcentagem\n" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("poisonResistance")) .. "^reset;" ..
    "^blue;" .. getStatPercent(status.stat("iceResistance")) .. "^reset;" .. 
    "^red;" .. getStatPercent(status.stat("fireResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("electricResistance")) .. "^reset;" ..
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

  widget.setText("infolayout.displayWeapons", self.hardcoreWeaponText[self.classType+1] .. "\n\n^green;Todas as Classes podem usar a\nBroken Protectorate Broadsword!\nTodas as classes podem usar Arcos de Caça.^reset;")
  if status.statPositive("ivrpghardcore") then
    widget.setVisible("infolayout.displayWeapons", true)
  else
    widget.setVisible("infolayout.displayWeapons", false)
  end

  --[["^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. (status.statPositive("poisonStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("poisonResistance"))) .. "^reset;" ..
    "^blue;" .. (status.statPositive("iceStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("iceResistance"))) .. "^reset;" .. 
    "^red;" .. (status.statPositive("fireStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("fireResistance"))) .."^reset;" .. 
    "^yellow;" .. (status.statPositive("electricStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("electricResistance"))) .. "^reset;" ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..]]

end

function unlockTech()
  local classType = player.currency("classtype")
  local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or 4))
  local tech = getTechEnableName(classType, checked)
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1))
end

function getTechEnableName(classType, checked)
  if classType == 1 then
    return checked == 1 and "knightbash" or (checked == 2 and "knightslam" or (checked == 3 and "knightarmorsphere" or "knightcharge!"))
  elseif classType == 2 then
    return checked == 1 and "wizardgravitysphere" or (checked == 2 and "wizardhover" or (checked == 3 and "wizardtranslocate" or "wizardmagicshield"))
  elseif classType == 3 then
    return checked == 1 and "ninjaflashjump" or (checked == 2 and "ninjavanishsphere" or (checked == 3 and "ninjaassassinate" or "ninjawallcling"))
  elseif classType == 4 then
    return checked == 1 and "soldiermre" or (checked == 2 and "soldiermarksman" or (checked == 3 and "soldierenergypack" or "soldiertanksphere"))
  elseif classType == 5 then
    return checked == 1 and "roguedeadlystance" or (checked == 2 and "roguetoxicsphere" or (checked == 3 and "rogueescape" or "roguetoxicaura"))
  elseif classType == 6 then
    return checked == 1 and "explorerglide" or (checked == 2 and "explorerenhancedmovement" or (checked == 3 and "explorerdrillsphere" or "explorerenhancedjump"))
  end
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
    local classType = player.currency("classtype")
    local techName = getTechEnableName(classType, tonumber(string.sub(tech,9,9)))
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
  uncheckTechButtons(name)
  if not widget.getChecked("classlayout.techicon1") and not widget.getChecked("classlayout.techicon2") and not widget.getChecked("classlayout.techicon3") and not widget.getChecked("classlayout.techicon4") then
    widget.setText("classlayout.techtext", "Selecione uma habilidade para ler sobre ela e desbloqueá-la, se possível.")
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
  if name == "techicon1" then
    widget.setText("classlayout.techtext", getTechText(1))
    widget.setText("classlayout.techname", getTechName(1))
    widget.setText("classlayout.techtype", getTechType(1) .. " ")
    unlockTechVisible(name, 4)
  elseif name == "techicon2" then
    widget.setText("classlayout.techtext",  getTechText(2))
    widget.setText("classlayout.techname", getTechName(2))
    widget.setText("classlayout.techtype", getTechType(2) .. " ")
    unlockTechVisible(name, 8)
  elseif name == "techicon3" then
    widget.setText("classlayout.techtext",  getTechText(3))
    widget.setText("classlayout.techname", getTechName(3))
    widget.setText("classlayout.techtype", getTechType(3) .. " ")
    unlockTechVisible(name, 16)
  elseif name == "techicon4" then
    widget.setText("classlayout.techtext",  getTechText(4))
    widget.setText("classlayout.techname", getTechName(4))
    widget.setText("classlayout.techtype", getTechType(4) .. " ")
    unlockTechVisible(name, 32)
  end
end

function getTechText(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "Uma melhoria para a Corrida, enquanto corre, os inimigos recebem dano e knockback. O dano é duplicado ao segurar um escudo. Dano escala com Força e Velocidade de Corrida. O custo de energia diminui com Agilidade maior."
    or (num == 2 and "Uma melhoria para o Pulo Duplo, pressione [G] (Vincule [G] em seus Controles) enquanto no meio do ar para bater para baixo. Você não leva nenhum dano de queda ao pousar, e causa uma pequena explosão, causando dano a inimigos. O Dano escala com Força e distância de queda da ativação."
      or (num == 3 and "Uma melhoria para a Esfera de Espinhos, enquanto transformado, ignora knockback e causa dano de contato nos inimigos. A Armadura também é aumentada enquanto transformado." 
        or "Uma melhoria para o Esmagar. Enquanto corre, o jogador recebe Resistência Física. Enquanto o dano permanece o mesmo, inimigos são atordoados ao acertar. O Dano escala com Força e Velocidade de Corrida. O Custo de Energia diminui com Agilidade alta."))
  elseif classType == 2 then
    return num == 1 and "Uma melhoria para a Esfera de Espinhos, enquanto transformado você regenera um pouco e é afetado pela baixa gravidade. Além disso, segure o botão esquerdo para criar uma barreira que empurra os inimigos, drenando sua energia." 
    or (num == 2 and "Pressione [Espaço] enquanto estiver no ar para flutuar em direção ao seu cursor. Quanto mais longe o cursor, mais rápido você se move. Sua Energia drena enquanto você flutua. A velocidade de Flutuamento escala com Agilidade." 
      or (num == 3 and "Pressione [G] (Vincule [G] em seus Controles) para se teletransportar para o seu cursor (se possível). Há um leve tempo de recarga antes que você possa se teletransportar novamente. O Custo de Energia depende da Distância e Agilidade. Durante Missões (e em sua nave), Translocar é apenas na Linha de Visão!." 
        or "Pressione [F] para ativar um escudo mágico que fornece invulnerabilidade a você e aliados próximos. Drena energia enquanto ativo, e é desativado quando não há energia."))
  elseif classType == 3 then
    return num == 1 and "Pressione [Espaço] enquanto no ar para dar um impulso para frente. Por um curto período após o pulo, você é invulnerável a dano. Enquanto você permanecer no ar com energia restante, você é invulnerável a dano de queda. Você pode fazer isso duas vezes no ar." 
    or (num == 2 and "Pressione [F] para se transformar em uma bola de espinhos invulnerável. A Energia drena rapidamente enquanto estiver ativa. A invulnerabilidade termina quando você fica sem energia ou pressiona [F] enquanto transformado. Ao contrário das outras Esfera de Espinhos, a velocidade da escala com Agilidade." 
    or (num == 3 and "Pressione [G] (Vincule [G] em seus Controles) para desaparecer. Após 2 segundos, você aparece no seu cursor (se possível). Se estiver segurando uma arma afiada, da um corte onde você aparece. Durante o tempo de recarga, perde 20% de Resistência Física. O Custo de Energia depende da Distancia e Agilidade." 
    or "Uma melhoria para o Pulo Flash. Agarre às paredes, movendo-se contra elas durante um pulo, e atualize seus pulos ao fazê-lo. Pressione [S] para deslizar para baixo enquanto se agarra. Pressione [Espaço] enquanto agarrando ou deslizando para pular. Afaste-se da parede para sair."))
  elseif classType == 4 then
    return num == 1 and "Pressione [F] para comer uma MRE (Refeição Pronta para Comer), ganhando um pouco de comida e toda a sua energia. Há um tempo de recarga de 90 segundos antes que você possa fazer isso novamente. Enquanto o tempo de recarga estiver ativo, você ganha um pouco de regeneração de vida, mas sua velocidade geral diminui." 
    or (num == 2 and "Pressione [G] (Vincule [G] em seus Controles) para ganhar dano extra com armas de longo alcance e diminuição do tempo de regeneração de energia: no entanto, a velocidade e a resistência são diminuídas. Você pode encerrar o efeito pressionando [G] novamente. O tempo de recarga encurta se assim for." 
      or (num == 3 and "Uma Melhoria para o Pulo Duplo, pressione [Espaço] para arrancar em uma direção de sua escolha. Você pode mudar ligeiramente a sua trajetória enquanto estiver arrancando. A Duração da Arrancada escala com Agilidade. Você pode arrancar duas vezes no meio do ar." 
        or "Pressione [F] para mudar para uma Esfera de Espinhos de movimento lento. Clique com o botão esquerdo para disparar um míssil usando energia. Mantenha pressionado o botão direito para drenar sua energia para se proteger contra dano.\nCriado por SushiSquid!"))
  elseif classType == 5 then
    return num == 1 and "Pressione [G] (Vincule [G] em seus Controles) para ativar uma habilidade que aumenta o Fisico e Resistência a Veneno e concede imunidade a Knockback. Drena energia enquanto está ativo, e é desativado quando não há energia." 
    or (num == 2 and "Pressione [F] para se transformar em uma Esfera de Espinhos imune a veneno. Botão esquerdo enquanto transformado para disparar um anel de nuvens de veneno (Dano escala com Destreza). Mantenha o botão direito do mouse pressionado enquanto transformado para diminuir sua Barra de Fome para regenerar Vida e Energia." 
      or (num == 3 and "Uma Melhoria para o Pulo Duplo, pressione [Espaço] para se lançar em uma direção à sua escolha, deixando uma nuvem de fumaça para trás que desorienta inimigos. Inimigos desorientados ficam lentos e causam menos dano. O padrão é um lançamento para trás." 
        or "Pressione [G] (Vincule [G] em seus Controles) para ativar um campo tóxico que atinge inimigos com um veneno enfraquecedor. Esses inimigos tomam mais dano de veneno e sangramento. Drena energia enquanto está ativo, e é desativado quando não há energia."))
  elseif classType == 6 then
    return num == 1 and "Uma Melhoria para o Pulo Duplo, segure [W] para deslizar para frente, lentamente perdendo altitude. Você pode usar o seu pulo duplo enquanto desliza. O custo da energia do Deslizar diminui com Agilidade alta." 
    or (num == 2 and "Pressione [G] (Vincule [G] em seus Controles) para alternar entre Arrancada Aérea Melhorada e Corrida Melhorada. Arrancada Aérea Melhorada viaja mais do que Arrancada Aérea, e tem um tempo de recarga mais curto. Corrida Melhorada é mais rápido e custa menos energia do que a Corrida." 
      or (num == 3 and "Pressione [H] (Vincule [H] em seus Controles) para se transformar em uma Esfera de Espinhos rápida que pode pular. Pressione [F] para perfurar em velocidade incrível, drenando sua energia. Você pode perfurar se você está ou não transformado." 
        or "Uma Melhoria para o Deslizar. Ganhe mais três pulos no ar e um pulo na parede. Pulos no ar são 85% tão eficaz. Você se agarra às paredes um pouco mais longo do que o Pulo na Parede normal e desliza mais devagar. O custo de energia do Deslizar diminui com Agilidade maior."))
  end
end

function getTechName(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    widget.setFontColor("classlayout.techname", "blue")
    return num == 1 and "Esmagar" or (num == 2 and "Batida" or (num == 3 and "Esfera Blindada" or "Investida!"))
  elseif classType == 2 then
    widget.setFontColor("classlayout.techname", "magenta")
    return num == 1 and "Esfera de Gravidade" or (num == 2 and "Planar" or (num == 3 and "Translocar" or "Escudo Mágico"))
  elseif classType == 3 then
    widget.setFontColor("classlayout.techname", "red")
    return num == 1 and "Pulo Flash" or (num == 2 and "Esfera Desaparecedora" or (num == 3 and "Passo das Sombras" or "Agarrar Parede"))
  elseif classType == 4 then
    widget.setFontColor("classlayout.techname", "orange")
    return num == 1 and "MRE" or (num == 2 and "Atirador" or (num == 3 and "Energizar" or "Esfera Tanque"))
  elseif classType == 5 then
    widget.setFontColor("classlayout.techname", "green")
    return num == 1 and "Postura Mortal" or (num == 2 and "Esfera Tóxica" or (num == 3 and "Fuga!" or "Aura Tóxica"))
  elseif classType == 6 then
    widget.setFontColor("classlayout.techname", "yellow")
    return num == 1 and "Deslizar" or (num == 2 and "Arrancada Melhorada" or (num == 3 and "Esfera Broca" or "Deslizar Melhorado"))
  end
end

function getTechType(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "Corpo" or (num == 2 and "Perna" or (num == 3 and "Cabeça" or "Corpo"))
  elseif classType == 2 then
    return num == 1 and "Cabeça" or (num == 2 and "Perna" or (num == 3 and "Corpo" or "Cabeça"))
  elseif classType == 3 then
    return num == 1 and "Perna" or (num == 2 and "Cabeça" or (num == 3 and "Corpo" or "Perna"))
  elseif classType == 4 then
    return num == 1 and "Cabeça" or (num == 2 and "Corpo" or (num == 3 and "Perna" or "Cabeça"))
  elseif classType == 5 then
    return num == 1 and "Corpo" or (num == 2 and "Cabeça" or (num == 3 and "Perna" or "Corpo"))
  elseif classType == 6 then
    return num == 1 and "Perna" or (num == 2 and "Corpo" or (num == 3 and "Cabeça" or "Perna"))
  end
end

function uncheckTechButtons(name)
  widget.setVisible("classlayout.reqlvl", false)
  widget.setVisible("classlayout.unlockbutton", false)
  widget.setVisible("classlayout.unlockedtext", false)
  if name ~= "techicon1" then widget.setChecked("classlayout.techicon1", false) end
  if name ~= "techicon2" then widget.setChecked("classlayout.techicon2", false) end
  if name ~= "techicon3" then widget.setChecked("classlayout.techicon3", false) end
  if name ~= "techicon4" then widget.setChecked("classlayout.techicon4", false) end
end

function updateTechImages()
  local classType = player.currency("classtype")
  local className = ""
  if classType == 1 then
    className = "knight"
  elseif classType == 2 then
    className = "wizard"
  elseif classType == 3 then
    className = "ninja"
  elseif classType == 4 then
    className = "soldier"
  elseif classType == 5 then
    className = "rogue"
  elseif classType == 6 then
    className = "explorer"
  end
  widget.setButtonImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png"
  })
  widget.setButtonImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png"
  })
  widget.setButtonImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png"
  })
  widget.setButtonImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png"
  })
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

--[[function startingStats()
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
end]]

function updateStats()
  self.strength = player.currency("strengthpoint")
  widget.setText("statslayout.strengthamount",self.strength)
  self.agility = player.currency("agilitypoint")
  widget.setText("statslayout.agilityamount",self.agility)
  self.vitality = player.currency("vitalitypoint")
  widget.setText("statslayout.vitalityamount",self.vitality)
  self.vigor = player.currency("vigorpoint")
  widget.setText("statslayout.vigoramount",self.vigor)
  self.intelligence = player.currency("intelligencepoint")
  widget.setText("statslayout.intelligenceamount",self.intelligence)
  self.endurance = player.currency("endurancepoint")
  widget.setText("statslayout.enduranceamount",self.endurance)
  self.dexterity = player.currency("dexteritypoint")
  widget.setText("statslayout.dexterityamount",self.dexterity)
  widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
  widget.setText("statslayout.totalstatsamount", addStats())
  checkStatPoints()
end

function addStats()
  return self.strength+self.agility+self.vitality+self.vigor+self.intelligence+self.endurance+self.dexterity
end

function uncheckStatIcons(name)
  if name ~= "strength" then widget.setChecked("statslayout.strengthicon", false) end
  if name ~= "agility" then widget.setChecked("statslayout.agilityicon", false) end
  if name ~= "vitality" then widget.setChecked("statslayout.vitalityicon", false) end
  if name ~= "vigor" then widget.setChecked("statslayout.vigoricon", false) end
  if name ~= "intelligence" then widget.setChecked("statslayout.intelligenceicon", false) end
  if name ~= "endurance" then widget.setChecked("statslayout.enduranceicon", false) end
  if name ~= "dexterity" then widget.setChecked("statslayout.dexterityicon", false) end
end

function uncheckClassIcons(name)
  if name ~= "knight" then
    widget.setChecked("classeslayout.knighticon", false)
    widget.setFontColor("classeslayout.knighttitle", "white")
  end
  if name ~= "wizard" then
    widget.setChecked("classeslayout.wizardicon", false)
    widget.setFontColor("classeslayout.wizardtitle", "white")
  end
  if name ~= "ninja" then
    widget.setChecked("classeslayout.ninjaicon", false)
    widget.setFontColor("classeslayout.ninjatitle", "white")
  end
  if name ~= "soldier" then
    widget.setChecked("classeslayout.soldiericon", false)
    widget.setFontColor("classeslayout.soldiertitle", "white")
  end
  if name ~= "rogue" then
    widget.setChecked("classeslayout.rogueicon", false)
    widget.setFontColor("classeslayout.roguetitle", "white")
  end
  if name ~= "explorer" then
    widget.setChecked("classeslayout.explorericon", false)
    widget.setFontColor("classeslayout.explorertitle", "white")
  end
end

function changeStatDescription(name)
  if name == "strength" then widget.setText("statslayout.statdescription", "Aumenta Muito a Vida do Escudo.\nAumenta Significativamente o Dano Corpo-a-corpo de Duas Mãos.\nAumenta Minimamente a Resistência Física.") end
  if name == "agility" then widget.setText("statslayout.statdescription", "Aumenta Significativamente a Velocidade.\nAumenta a Altura do Pulo.\nDiminui o Dano de Queda.") end
  if name == "vitality" then widget.setText("statslayout.statdescription", "Aumenta Significativamente a Vida Maxima.\nDiminui a Taxa de Fome.") end
  if name == "vigor" then widget.setText("statslayout.statdescription", "Aumenta Significativamente a Energia Máxima.\nAumenta Muito a Taxa de Recarga de Energia.") end
  if name == "intelligence" then widget.setText("statslayout.statdescription", "Aumenta Muito a Taxa de Recarga de Energia.\nAumenta Muito o Dano de Cajados.\nDiminui o Atraso de Recarga de Energia.\nAumenta Ligeiramente o Dano de Varinhas.") end
  if name == "endurance" then widget.setText("statslayout.statdescription", "Aumenta a Resistência a Knockback.\nAumenta a Resistência Física.\nAumenta Moderadamente Todas as Outras Resistências.") end
  if name == "dexterity" then widget.setText("statslayout.statdescription", "Aumenta o Dano de Arma de Fogo e Arco.\nAumenta a Chance de Sangramento e Duração do Sangramento.\nAumenta Ligeiramente o Dano de Arma de Uma Mão.\nDiminui Ligeiramente o Dano de Queda.") end
  if name == "default" then widget.setText("statslayout.statdescription", "Clique no ícone de um status para ver o que ocorre\nquando esse status é aumentado.") end
end

function changeClassDescription(name)
  if name == "knight" then
    widget.setText("classeslayout.classdescription", "O Cavaleiro: Tanque Corpo-a-corpo. É melhor com Armas Corpo-a-corpo de Duas Mãos, mas ainda é excelente com Espada e Escudo. As habilidades do Cavaleiro melhoram principalmente as capacidades defensivas, embora todas tenham medidas ofensivas também. O Cavaleiro pode curar através do Bloqueio Perfeito, e tem alta Resistência a Knockback.") 
    widget.setFontColor("classeslayout.knighttitle", "blue")
    self.classTo = 1
  end
  if name == "wizard" then
    widget.setText("classeslayout.classdescription", "O Feiticeiro: Utilitário Longo Alcance. É melhor com Cajados e Varinhas. As habilidades do Feiticeiro principalmente melhoram a utilidade e movimento. O Feiticeiro pode aplicar aleatoriamente Status Elementais (Fogo, Gelo, Raio) aos inimigos ao bater neles, e se da melhor contra os Elementos, enquanto usando Varinhas ou Cajados.") 
    widget.setFontColor("classeslayout.wizardtitle", "magenta")
    self.classTo = 2
  end
  if name == "ninja" then
    widget.setText("classeslayout.classdescription", "O Ninja: Longo Alcance-Misto, DPS Evasivo. É melhor com Shurikens, mas ainda é ótimo com Armas de Uma Mão (que não seja de Ataque à Distância). As habilidades do Ninja principalmente melhoram o movimento e evasão. O Ninja tem mais facilidade de obter golpes críticos, e pode facilmente evitar Dano de Queda.") 
    widget.setFontColor("classeslayout.ninjatitle", "red")
    self.classTo = 3
  end
  if name == "soldier" then
    widget.setText("classeslayout.classdescription", "O Soldado: Tanque de Longo Alcance. É melhor com Armas de Longo Alcance de Duas Mãos , mas ainda pode utilizar Armas de Longo Alcance de Uma Mão razoavelmente bem. As habilidades do Soldado principalmente melhoram a utilidade e defesa. O soldado da mais dano enquanto está com a Energia cheia, e pode atordoar aleatoriamente inimigos ao bater neles.") 
    widget.setFontColor("classeslayout.soldiertitle", "orange")
    self.classTo = 4
  end
  if name == "rogue" then
    widget.setText("classeslayout.classdescription", "O Ladino: Longo Alcance-Misto de Controle Coletivo (CC). É melhor com Armas de Uma Mão. As habilidades do Ladino principalmente melhoram as capacidades ofensivas, mas também aumentam a Resistência Física, Venenosa e Knockback. O Ladino pode aleatoriamente Envenenar os inimigos e é mais resistente a Veneno enquanto a Barra de Comida está quase cheia.") 
    widget.setFontColor("classeslayout.roguetitle", "green")
    self.classTo = 5
  end
  if name == "explorer" then
    widget.setText("classeslayout.classdescription", "O Explorador: Utilitário Evasivo. É melhor com Ferramentas, como Picaretas, Lanternas ou o Manipulator de Matéria. As habilidades do Explorador principalmente melhoram movimento e mineração. O Explorador brilha enquanto a Vida é maior que a metade e é um pouco mais resistente a Dano Físico.") 
    widget.setFontColor("classeslayout.explorertitle", "yellow")
    self.classTo = 6
  end
  if name == "default" then
    widget.setText("classeslayout.classdescription", "Clique em um ícone de classe para informações sobre essa classe.")
    uncheckClassIcons("default")
    self.classTo = 0
  end
end

function enableStatButtons(enable)
  if player.currency("classtype") == 0 then
    enable = false
    widget.setVisible("statslayout.statprevention",true)
  else
    widget.setVisible("statslayout.statprevention",false)
  end
  widget.setButtonEnabled("statslayout.raisestrength", self.strength ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisedexterity", self.dexterity ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseendurance", self.endurance ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseintelligence", self.intelligence ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevigor", self.vigor ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevitality", self.vitality ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseagility", self.agility ~= 50 and enable)
end

function chooseClass()
  player.addCurrency("classtype", self.classTo)
  self.class = self.classTo
  addClassStats()
  changeToClasses()
end

function addClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.addCurrency("strengthpoint", 5)
    player.addCurrency("endurancepoint", 4)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Feiticeiro
    player.addCurrency("intelligencepoint", 7)
    player.addCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.addCurrency("agilitypoint", 5)
    player.addCurrency("dexteritypoint", 6)
    player.addCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldado
    player.addCurrency("vigorpoint", 5)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vitalitypoint", 2)
  elseif player.currency("classtype") == 5 then
    --Ladino
    player.addCurrency("agilitypoint", 3)
    player.addCurrency("endurancepoint", 3)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorador
    player.addCurrency("agilitypoint", 4)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("vigorpoint", 3)
    player.addCurrency("vitalitypoint", 4)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

--deprecated, don't use
function consumeClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.consumeCurrency("strengthpoint", 5)
    player.consumeCurrency("endurancepoint", 4)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Feiticeiro
    player.consumeCurrency("intelligencepoint", 7)
    player.consumeCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.consumeCurrency("agilitypoint", 5)
    player.consumeCurrency("dexteritypoint", 6)
    player.consumeCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldado
    player.consumeCurrency("vitalitypoint", 5)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Ladino
    player.consumeCurrency("agilitypoint", 3)
    player.consumeCurrency("endurancepoint", 3)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorador
    player.consumeCurrency("agilitypoint", 4)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 4)
  end
  updateStats()
end
--

function areYouSure(name)
  name = string.gsub(name,"resetbutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  --sb.logInfo(name.."test"..name2)
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

--deprecated, don't use
function resetClass()
  notSure("nobuttoncl")
  consumeClassStats()
  player.consumeCurrency("classtype",player.currency("classtype"))
  changeToClasses()
end
--

function resetSkillBook()
  notSure("nobutton")
  consumeAllRPGCurrency()
  consumeMasteryCurrency()
  removeTechs()
end

function removeTechs()
  if self.class == 3 then
    player.makeTechUnavailable("ninjaassassinate")
    player.makeTechUnavailable("ninjaflashjump")
    player.makeTechUnavailable("ninjawallcling")
    player.makeTechUnavailable("ninjavanishsphere")
  elseif self.class == 2 then
    player.makeTechUnavailable("wizardmagicshield")
    player.makeTechUnavailable("wizardgravitysphere")
    player.makeTechUnavailable("wizardtranslocate")
    player.makeTechUnavailable("wizardhover")
  elseif self.class == 1 then
    player.makeTechUnavailable("knightslam")
    player.makeTechUnavailable("knightbash")
    player.makeTechUnavailable("knightcharge!")
    player.makeTechUnavailable("knightarmorsphere")
  elseif self.class == 5 then
    player.makeTechUnavailable("roguetoxicaura")
    player.makeTechUnavailable("roguetoxicsphere")
    player.makeTechUnavailable("roguedeadlystance")
    player.makeTechUnavailable("rogueescape")
    --Deprecated
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
  elseif self.class == 4 then
    player.makeTechUnavailable("soldiertanksphere")
    player.makeTechUnavailable("soldierenergypack")
    player.makeTechUnavailable("soldiermarksman")
    player.makeTechUnavailable("soldiermre")
    --Deprecated
    player.makeTechUnavailable("soldiermissilestrike")
  elseif self.class == 6 then
    player.makeTechUnavailable("explorerenhancedjump")
    player.makeTechUnavailable("explorerenhancedmovement")
    player.makeTechUnavailable("explorerdrillsphere")
    player.makeTechUnavailable("explorerglide")
    --Deprecated
    player.makeTechUnavailable("explorerdrill")
  end
end

function updateClassWeapon()
  if self.class == 0 then return end
  if player.hasCompletedQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", self.classWeaponText[self.class])
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", true)
  elseif self.level < 12 then
    widget.setFontColor("classlayout.weaponreqlvl", "red")
    widget.setText("classlayout.weaponreqlvl", "Nível Requerido: 15")
    widget.setVisible("classlayout.weaponreqlvl", true)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", false)
  elseif player.hasQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", "Complete a primeira missão para obter mais informações.")
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
  player.startQuest(self.quests[self.class])
  widget.setVisible("classlayout.unlockquestbutton", false)
  widget.setText("classlayout.classweapontext", "Complete a primeira missão para obter mais informações.")
  widget.setVisible("classlayout.classweapontext", true)
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
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
  if name ~= "fire" then
    widget.setChecked("affinitieslayout.fireicon", false)
    widget.setFontColor("affinitieslayout.firetitle", "white")
  end
  if name ~= "ice" then
    widget.setChecked("affinitieslayout.iceicon", false)
    widget.setFontColor("affinitieslayout.icetitle", "white")
  end
  if name ~= "electric" then
    widget.setChecked("affinitieslayout.electricicon", false)
    widget.setFontColor("affinitieslayout.electrictitle", "white")
  end
  if name ~= "poison" then
    widget.setChecked("affinitieslayout.poisonicon", false)
    widget.setFontColor("affinitieslayout.poisontitle", "white")
  end
end

function changeAffinityDescription(name)
  if name == "fire" then
    widget.setText("affinitieslayout.affinitydescription", "Fogo, a Afinidade Poderosa. Esta Afinidade concede Imunidades e Resistências baseadas em Fogo, e um Aumento Médio no Status de Vigor. Fornece melhores Imunidades e um Grande Aumento no Status de Força quando melhorado. Tenha cuidado, pois escolher essa Afinidade enfraquece você enquanto estiver Submerso, e torna-o fraco a Veneno.") 
    widget.setFontColor("affinitieslayout.firetitle", "red")
    self.affinityTo = 1
  end
  if name == "poison" then
    widget.setText("affinitieslayout.affinitydescription", "Veneno, a Afinidade Proficiente. Esta Afinidade concede Imunidades e Resistências baseadas em Veneno, e um Aumento Pequeno no Status de Vigor, Destreza e Agilidade. Fornece melhores Imunidades e um Grande Aumento no Status de Destreza quando melhorado. Tenha cuidado, pois escolher esta Afinidade diminui a sua Vida Maxima e torna-o fraco a Eletricidade.") 
    widget.setFontColor("affinitieslayout.poisontitle", "green")
    self.affinityTo = 2
  end
  if name == "ice" then
    widget.setText("affinitieslayout.affinitydescription", "Gelo, a Afinidade Protetora. Esta afinidade concede Imunidades e Resistências baseadas no Gelo, e um Aumento Médio no Status de Vitalidade. Fornece melhores Imunidades e um Aumento Grande no Status de Resistência quando melhorado. Tenha cuidado, pois escolher essa Afinidade reduz sua Velocidade e Altura no Pulo, e torna-o fraco a Fogo.") 
    widget.setFontColor("affinitieslayout.icetitle", "blue")
    self.affinityTo = 3
  end
  if name == "electric" then
    widget.setText("affinitieslayout.affinitydescription", "Eletricidade, a Afinidade Perceptiva. Esta Afinidade concede Imunidades e Resistências baseadas em Eletricidade, um Aumento Médio no Status de Agilidade. Fornece melhores Imunidades e um Grande Aumento no Status de Inteligência quando melhorado. Tenha cuidado, pois escolher essa Afinidade enfraquece você enquanto estiver Submerso, e torna você fraco a Gelo.") 
    widget.setFontColor("affinitieslayout.electrictitle", "yellow")
    self.affinityTo = 4
  end
  if name == "default" then
    widget.setText("affinitieslayout.affinitydescription", "Clique no ícone de uma Afinidade para ver o que essa Afinidade faz.")
    uncheckAffinityIcons("default")
    self.affinityTo = 0
  end
end

function updateAffinityTab()
  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("affinitylayout.affinitytitle","Sem Classe Ainda")
    widget.setImage("affinitylayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("affinitylayout.affinitytitle","Fogo")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+10% de chance de Cauterizar inimigos ao causar dano. Inimigos Cauterizados têm -25% de Poder e são Queimados durante a duração do Cauterizar.")
    widget.setText("affinitylayout.statscalingtext","+3 Vigor")

    widget.setText("affinitylayout.immunitytext", "Status de Fogo\nCalor")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Veneno\n-30% Energia enquanto submerso\n-1 HP/s enquanto submerso")
    widget.setText("affinitylayout.upgradetext", "+20% de chance de Cauterizar inimigos\n+5 Força\nImunidades Adicionadas:\nDano de Fogo\nLava\nCalor Extremo")
  elseif affinity == 2 then
    widget.setText("affinitylayout.affinitytitle","Veneno")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+10% de chance de Intoxicar inimigos ao causar dano. Inimigos Intoxicados têm -25% Vida Maxima e são Envenenados durante a duração do Intoxicar.")
    widget.setText("affinitylayout.statscalingtext","+1 Vigor\n+1 Destreza\n+1 Agilidade")

    widget.setText("affinitylayout.immunitytext", "Status de Veneno\nPiche\nRadiação")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência Elétrica\n-15% Vida")
    widget.setText("affinitylayout.upgradetext", "+20% de chance de Intoxicar inimigos\n+5 Destreza\nImunidades Adicionadas:\nDano de Veneno\nRadiação Extrema\nProto")
  elseif affinity == 3 then
    widget.setText("affinitylayout.affinitytitle","Gelo")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+10% de chance de Fragilizar inimigos ao causar dano. Os inimigos Fragilizados têm -25% de Resistência Física e se despedaçam quando são mortos. Esta Explosão de Gelo causa Dano de Gelo e deixa inimigos Lentos.")
    widget.setText("affinitylayout.statscalingtext","+3 Vitalidade")

    widget.setText("affinitylayout.immunitytext", "Status de Gelo\nMolhado\nFrio")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Fogo\n-15% Velocidade\n-15% Pulo")
    widget.setText("affinitylayout.upgradetext", "+20% de chance de Fragilizar inimigos\n+5 Resistência\nImunidades Adicionadas:\nDano de Gelo\nRespiração\nFrio Extremo")
  elseif affinity == 4 then
    widget.setText("affinitylayout.affinitytitle","Eletricidade")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+10% chance de Sobrecarregar inimigos ao causar dano. Os inimigos Sobrecarregados têm -25% Velocidade e passam um relâmpago eletrizante para inimigos próximos.")
    widget.setText("affinitylayout.statscalingtext","+3 Agilidade")

    widget.setText("affinitylayout.immunitytext", "Lentidão\nDano Elétrico")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Gelo\n-30% Vida enquanto submerso\n-1 E/s enquanto submerso")
    widget.setText("affinitylayout.upgradetext", "+20% chance de Sobrecarregar inimigos\n+5 Inteligência\nImunidades Adicionadas:\nDano Elétrico\nRadiação\nShadow")
  elseif affinity == 5 then
    widget.setText("affinitylayout.affinitytitle","Infernal")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+30% de chance de Cauterizar inimigos ao causar dano. Inimigos Cauterizados têm -25% de Poder e são Queimados durante a duração do Cauterizar.")
    widget.setText("affinitylayout.statscalingtext","+3 Vigor\n+5 Força")

    widget.setText("affinitylayout.immunitytext", "Dano de Fogo\nLava\nCalor Extremo (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Veneno\n-30% Energia enquanto submerso\n-1 HP/s enquanto submerso")
    widget.setText("affinitylayout.upgradetext", "Totalmente Melhorado!")
  elseif affinity == 6 then
    widget.setText("affinitylayout.affinitytitle","Tóxico")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+30% de chance de Intoxicar inimigos ao causar dano. Inimigos Intoxicados têm -25% Vida Maxima e são Envenenados durante a duração do Intoxicar.")
    widget.setText("affinitylayout.statscalingtext","+1 Vigor\n+1 Agilidade\n+6 Destreza")

    widget.setText("affinitylayout.immunitytext", "Dano de Veneno\nPiche\nRadiação Extrema (FU)\nProto (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência Elétrica\n-15% Vida")
    widget.setText("affinitylayout.upgradetext", "Totalmente Melhorado!")
  elseif affinity == 7 then
    widget.setText("affinitylayout.affinitytitle","Crio")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+30% de chance de Fragilizar inimigos ao causar dano. Os inimigos Fragilizados têm -25% de Resistência Física e se despedaçam quando são mortos. Esta Explosão de Gelo causa Dano de Gelo e deixa inimigos Lentos.\n^blue;Quando sua Vida cai abaixo de um terço, os inimigos próximos são empurrados para tras e desacelerados.")
    widget.setText("affinitylayout.statscalingtext","+3 Vitalidade\n+5 Resistência")

    widget.setText("affinitylayout.immunitytext", "Dano de Gelo\nMolhado\nRespiração\nFrio Extremo (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Fogo\n-15% Velocidade\n-15% Pulo")
    widget.setText("affinitylayout.upgradetext", "Totalmente Melhorado!")
  elseif affinity == 8 then
    widget.setText("affinitylayout.affinitytitle","Arc")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+30% chance de Sobrecarregar inimigos ao causar dano. Os inimigos Sobrecarregados têm -25% Velocidade e passam um relâmpago eletrizante para inimigos próximos.\n^yellow;Ao gastar toda a Energia, libere uma explosão Elétrica que causa dano maciço e causa Sobrecarregar.")
    widget.setText("affinitylayout.statscalingtext","+3 Agilidade\n+5 Inteligência")

    widget.setText("affinitylayout.immunitytext", "Dano Eletrico\nLentidão\nRadiação\nShadow (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25% Resistência a Gelo\n-30% Vida enquanto submerso\n-1 E/s enquanto submerso")
    widget.setText("affinitylayout.upgradetext", "Totalmente Melhorado!")
  end

  if affinity > 4 then
    widget.setVisible("affinitylayout.effecttext", false)
  elseif affinity > 0 then
    widget.setVisible("affinitylayout.effecttext", true)
  end

  if status.statPositive("ivrpgaesthetics") then
    widget.setText("affinitylayout.aestheticstoggletext", "Ativo")
  else
    widget.setText("affinitylayout.aestheticstoggletext", "Inativo")
  end
end

function addAffinityStats()
  if player.currency("affinitytype") == 1 then
      --Flame
    addAffintyStatsHelper("vigorpoint", 3)
  elseif player.currency("affinitytype") == 2 then
    --Venom
    addAffintyStatsHelper("vigorpoint", 1)
    addAffintyStatsHelper("dexteritypoint", 1)
    addAffintyStatsHelper("agilitypoint", 1)
  elseif player.currency("affinitytype") == 3 then
    --Frost
    addAffintyStatsHelper("vitalitypoint", 3)
  elseif player.currency("affinitytype") == 4 then
    --Shock
    addAffintyStatsHelper("agilitypoint", 3)
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

--Deprecated
function consumeAffinityStats()
  --[[if player.currency("affinitytype") == 1 then
      --Flame
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 2 then
    --Venom
    player.consumeCurrency("vigorpoint", 1)
    player.consumeCurrency("vitalitypoint", 1)
    player.consumeCurrency("agilitypoint", 1)
  elseif player.currency("classtype") == 3 then
    --Frost
    player.consumeCurrency("vitalitypoint", 3)
  elseif player.currency("classtype") == 4 then
    --Shock
    player.consumeCurrency("agilitypoint", 3)
  elseif player.currency("cla sstype") == 5 then
    --Infernal
    player.consumeCurrency("strengthpoint", 5)
  elseif player.currency("classtype") == 6 then
    --Toxic
    player.consumeCurrency("dexteritypoint", 5)
  elseif player.currency("classtype") == 7 then
    --Cryo
    player.consumeCurrency("endurancepoint", 5)
  elseif player.currency("classtype") == 8 then
    --Arc
    player.consumeCurrency("intelligencepoint", 5)
  end
  updateStats()]]
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
  player.consumeCurrency("experienceorb", self.xp - 100)
  player.consumeCurrency("currentlevel", self.level - 1)
  player.consumeCurrency("statpoint", player.currency("statpoint"))
  player.consumeCurrency("strengthpoint",player.currency("strengthpoint"))
  player.consumeCurrency("agilitypoint",player.currency("agilitypoint"))
  player.consumeCurrency("vitalitypoint",player.currency("vitalitypoint"))
  player.consumeCurrency("vigorpoint",player.currency("vigorpoint"))
  player.consumeCurrency("intelligencepoint",player.currency("intelligencepoint"))
  player.consumeCurrency("endurancepoint",player.currency("endurancepoint"))
  player.consumeCurrency("dexteritypoint",player.currency("dexteritypoint"))
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
  removeDeprecatedTechs()
end

function purchaseShop()
  player.consumeCurrency("masterypoint", 5)
  player.giveItem("ivrpgmasteryshop")
end

function refine()
  local xp = self.xp - 250000
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

  local prog1 = math.floor(status.stat("ivrpgchallenge1progress"))
  local prog2 = math.floor(status.stat("ivrpgchallenge2progress"))
  local prog3 = math.floor(status.stat("ivrpgchallenge3progress"))

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
    status.clearPersistentEffects("ivrpgchallenge1progress")
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
    status.clearPersistentEffects("ivrpgchallenge2progress")
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
    status.clearPersistentEffects("ivrpgchallenge3progress")
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
  status.clearPersistentEffects("ivrpgchallenge1progress")
  status.clearPersistentEffects("ivrpgchallenge2progress")
  status.clearPersistentEffects("ivrpgchallenge3progress")
end

function removeDeprecatedTechs()
  player.makeTechUnavailable("roguecloudjump")
  player.makeTechUnavailable("roguetoxiccapsule")
  player.makeTechUnavailable("roguepoisondash")
  player.makeTechUnavailable("soldiermissilestrike")
  player.makeTechUnavailable("explorerdrill")
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