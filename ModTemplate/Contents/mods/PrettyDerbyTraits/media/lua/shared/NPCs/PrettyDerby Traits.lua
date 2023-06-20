require('NPCs/MainCreationMethods');

local function initPrettyDerbyTrait()
    local PrettyDerbyTraits = TraitFactory.addTrait("PrettyDerbyTraits", getText("UI_trait_PrettyDerbyTraits"), 1, getText("UI_trait_PrettyDerbyTraitsdesc"), false, false);


end

Events.OnGameBoot.Add(initPrettyDerbyTrait);
