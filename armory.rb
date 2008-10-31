class Armory
  def self.get_points(teamsize, rating)
    teamsize = teamsize.to_i
    rating = rating.to_i
    if rating > 1500
      points = ((1426.79 / (1+918.836*2.71828 ** (-0.00386405* rating))).round)
    else
      points = ((0.38*rating-194).round)
    end
    if teamsize == 5
      points.to_s
    elsif teamsize == 3
      (points * 0.8).round.to_s
    elsif teamsize == 2
      (points * 0.7).round.to_s
    end
  end
  def self.get_spec(treeone,treetwo,treethree,characterclass)
    total = treeone.to_i + treetwo.to_i + treethree.to_i
    avg = total / 3
    majority = (avg * 2) - 1
    hybrid = avg - 3
    output = {}
    if treeone.to_i >= majority
      output = output.merge({treeone.to_i => @@class_talent_trees[characterclass][0]})
    elsif treetwo.to_i >= majority
      output = output.merge({treetwo.to_i => @@class_talent_trees[characterclass][1]})
    elsif treethree.to_i >= majority
      output = output.merge({treethree.to_i => @@class_talent_trees[characterclass][2]})
    else
      if treeone.to_i >= hybrid
        output = output.merge({treeone.to_i => @@class_talent_trees[characterclass][0]})
      end
      if treetwo.to_i >= hybrid
        output = output.merge({treetwo.to_i => @@class_talent_trees[characterclass][1]})
      end
      if treethree.to_i >= hybrid
        output = output.merge({treethree.to_i => @@class_talent_trees[characterclass][2]})
      end
    end
    output
  end
  def self.get_stats(domain, realm, charactername)
    begin
      url = URI.parse("http://#{domain}/character-sheet.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        armoryinfo = (REXML::Document.new xmldoc).root
        if armoryinfo.elements['/page/characterInfo/character'] and armoryinfo.elements['/page/characterInfo/character'].attributes.any?
          character = {
            #General info, class, race, etc
            'characterclass' => armoryinfo.elements['/page/characterInfo/character'].attributes['class'],
            'faction' => armoryinfo.elements['/page/characterInfo/character'].attributes['faction'],
            'gender' => armoryinfo.elements['/page/characterInfo/character'].attributes['gender'],
            'guild' => armoryinfo.elements['/page/characterInfo/character'].attributes['guildName'],
            'level' => armoryinfo.elements['/page/characterInfo/character'].attributes['level'],
            'name' => armoryinfo.elements['/page/characterInfo/character'].attributes['name'],
            'race' => armoryinfo.elements['/page/characterInfo/character'].attributes['race'],
            'realm' => armoryinfo.elements['/page/characterInfo/character'].attributes['realm'],
            'title' => armoryinfo.elements['/page/characterInfo/character'].attributes['title'],
            #Talents
            'talents_1' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpec'].attributes["treeOne"],
            'talents_2' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpec'].attributes["treeTwo"],
            'talents_3' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpec'].attributes["treeThree"],
            #PVP
            'pvpkills' => armoryinfo.elements['/page/characterInfo/characterTab/pvp/lifetimehonorablekills'].attributes["value"],
            #Health and Mana
            'health' => armoryinfo.elements['/page/characterInfo/characterTab/characterBars/health'].attributes["effective"],
            'mana' => armoryinfo.elements['/page/characterInfo/characterTab/characterBars/secondBar'].attributes["effective"],
            #base stats
            'strength' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/strength'].attributes["effective"],
            'agility' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/agility'].attributes["effective"],
            'stamina' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/stamina'].attributes["effective"],
            'intellect' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/intellect'].attributes["effective"],
            'spirit' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/spirit'].attributes["effective"],
            'armor' => armoryinfo.elements['/page/characterInfo/characterTab/baseStats/armor'].attributes["effective"],
            #melee stats
            'melee_expertise' => armoryinfo.elements['/page/characterInfo/characterTab/melee/expertise'].attributes["percent"],
            'melee_mainhand_damage' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandDamage'].attributes["min"]+"-"+armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandDamage'].attributes["max"],
            'melee_offhand_damage' => armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["min"]+"-"+armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["max"],
            'melee_mainhand_damage_dps' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandDamage'].attributes["dps"],
            'melee_offhand_damage_dps' => armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["dps"],
            'melee_mainhand_speed' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandSpeed'].attributes["value"],
            'melee_offhand_speed' => armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandSpeed'].attributes["value"],
            'melee_power' => armoryinfo.elements['/page/characterInfo/characterTab/melee/power'].attributes["effective"],
            'melee_hitrating' => armoryinfo.elements['/page/characterInfo/characterTab/melee/hitRating'].attributes["increasedHitPercent"],
            'melee_crit' => armoryinfo.elements['/page/characterInfo/characterTab/melee/critChance'].attributes["percent"],
            #range stats
            'range_skill' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/weaponSkill'].attributes["value"],
            'range_damage' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["min"]+"-"+armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["max"],
            'range_damage_dps' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["dps"],
            'range_speed' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/speed'].attributes["value"],
            'range_power' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/power'].attributes["effective"],
            'range_hitrating' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/hitRating'].attributes["increasedHitPercent"],
            'range_crit' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/critChance'].attributes["percent"],
            #spell stats
            'spell_arcane_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/arcane'].attributes["value"],
            'spell_fire_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/fire'].attributes["value"],
            'spell_frost_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/frost'].attributes["value"],
            'spell_holy_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/holy'].attributes["value"],
            'spell_nature_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/nature'].attributes["value"],
            'spell_shadow_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/shadow'].attributes["value"],
            'spell_petbonus_damage' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusDamage/petBonus'].attributes["damage"],
            'spell_bonus_healing' => armoryinfo.elements['/page/characterInfo/characterTab/spell/bonusHealing'].attributes["value"],
            'spell_hitrating' => armoryinfo.elements['/page/characterInfo/characterTab/spell/hitRating'].attributes["increasedHitPercent"],
            'spell_arcane_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/arcane'].attributes["percent"],
            'spell_fire_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/fire'].attributes["percent"],
            'spell_frost_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/frost'].attributes["percent"],
            'spell_holy_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/holy'].attributes["percent"],
            'spell_nature_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/nature'].attributes["percent"],
            'spell_shadow_crit' => armoryinfo.elements['/page/characterInfo/characterTab/spell/critChance/shadow'].attributes["percent"],
            'spell_penetration' => armoryinfo.elements['/page/characterInfo/characterTab/spell/penetration'].attributes["value"],
            'spell_manaregen' => armoryinfo.elements['/page/characterInfo/characterTab/spell/manaRegen'].attributes["casting"],
            #defenses
            'defenses_armor' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/armor'].attributes["effective"],
            'defenses_defense' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/defense'].attributes["value"] +"+"+ armoryinfo.elements['/page/characterInfo/characterTab/defenses/defense'].attributes["plusDefense"],
            'defenses_dodge' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/dodge'].attributes["percent"],
            'defenses_parry' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/parry'].attributes["percent"],
            'defenses_block' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/block'].attributes["percent"],
            'defenses_resilience' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/resilience'].attributes["value"],
          }
          spec = Armory.get_spec(character["talents_1"],character["talents_2"],character["talents_3"],character["characterclass"].downcase)
          if (@@class_show_stats.has_key?(character["characterclass"].downcase))
            output = "#{character["name"].capitalize}, Level #{character["level"]} #{character["race"]} #{character["gender"]} #{character["characterclass"]} (#{character["talents_1"]}/#{character["talents_2"]}/#{character["talents_3"]}): "
            stats = {}
            @@class_show_stats[character["characterclass"].downcase]["base"].sort.each do |statkey, stat|
              stats = stats.merge({statkey => stat})
            end
            spec.each do |speckey, specvalue|
              if @@class_show_stats[character["characterclass"].downcase].has_key?(specvalue)
                @@class_show_stats[character["characterclass"].downcase][specvalue].sort.each do |statkey, stat|
                  stats = stats.merge({statkey => stat})
                end
              end
            end
            stats.sort.each do |statkey,stat|
              output = output + " #{stat}: #{character[statkey]};"
            end
            output
          else
            "Sorry, I don't know how to handle your class yet."
          end
        else
          "Character #{charactername}, not found."
        end
    rescue => err
      "Error retrieving character profile: #{err.message}"
    end
  end
  def self.get_buffs(domain, realm, charactername)
    begin
      output = nil
      url = URI.parse("http://#{domain}/character-sheet.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        armoryinfo = (REXML::Document.new xmldoc).root
        if armoryinfo.elements['/page/characterInfo/character'] and armoryinfo.elements['/page/characterInfo/character'].attributes.any?
          armoryinfo.elements.each('/page/characterInfo/characterTab/buffs/spell') do |buff|
            if output.nil?
              output = "Buffs: "
              output = output + "#{buff.attributes["name"]}"
            else
              output = output + ", #{buff.attributes["name"]}"
            end
          end
          output
        else
          ""
        end
    rescue => err
      "Error retrieving character buffs: #{err.message}"
    end
  end
  def self.get_buff_info(domain, realm, charactername, buffname)
    begin
      output = nil
      url = URI.parse("http://#{domain}/character-sheet.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        armoryinfo = (REXML::Document.new xmldoc).root
        if armoryinfo.elements['/page/characterInfo/character'] and armoryinfo.elements['/page/characterInfo/character'].attributes.any?
          armoryinfo.elements.each('/page/characterInfo/characterTab/buffs/spell') do |buff|
            if buffname == buff.attributes["name"]
              output = buff.attributes["name"] + ": " + buff.attributes["effect"]
            end
          end
          if !output.nil?
            output
          else
            "Could not find buff"
          end
        else
          "Character not found"
        end
    rescue => err
      "Error retrieving character buffs: #{err.message}"
    end
  end
end

@@class_talent_trees = {
  'druid' => ['balance', 'feral', 'restoration'],
  'hunter' => ['beastmastery', 'marksmanship', 'survival'],
  'mage' => ['arcane', 'fire', 'frost'],
  'paladin' => ['holy', 'protection', 'retribution'],
  'priest' => ['discipline', 'holy', 'shadow'],
  'rogue' => ['assassination', 'combat', 'subtlety'],
  'shaman' => ['elemental', 'enhancement', 'restoration'],
  'warlock' => ['affliction', 'demonology', 'destruction'],
  'warrior' => ['arms', 'fury', 'protection'],
}

@@class_show_stats = {
  'druid' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'balance' => {'spell_arcane_damage' => 'Arcane Damage', 'spell_arcane_crit' => 'Arcane Crit %', 'spell_nature_damage' => 'Nature Damage', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration'},
    'feral' => {'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %'},
    'restoration' => {'spell_bonus_healing' => 'Plus Healing', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5'},
  },
  'hunter' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'range_power' => 'Ranged Attack Power', 'range_damage' => 'Ranged Damage', 'range_speed' => 'Ranged Attack Speed', 'range_damage_dps' => 'Ranged DPS', 'range_hitrating' => 'Ranged Hit %', 'range_crit' => 'Ranged Crit %', 'defenses_resilience' => 'Resilience', 'spell_manaregen' => 'MP5'},
  },
  'mage' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'defenses_resilience' => 'Resilience'},
    'arcane' => {'spell_arcane_damage' => 'Arcane Damage', 'spell_arcane_crit' => 'Arcane Crit %'},
    'fire' => {'spell_fire_damage' => 'Fire Damage', 'spell_fire_crit' => 'Fire Crit %'},
    'frost' => {'spell_frost_damage' => 'Frost Damage', 'spell_frost_crit' => 'Frost Crit %'},
  },
  'paladin' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'holy' => {'intellect' => 'Intellect', 'spell_holy_damage' => 'Holy Damage', 'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5'},  
    'protection' => {'spell_holy_damage' => 'Holy Damage', 'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'defenses_parry' => 'Parry %', 'defenses_block' => 'Block %'},
    'retribution' => {'spell_holy_damage' => 'Holy Damage', 'melee_expertise' => 'Expertise %', 'melee_mainhand_damage' => 'Weapon Damage', 'melee_mainhand_damage_dps' => 'Weapon DPS', 'melee_mainhand_speed' => 'Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
  },
  'priest' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'discipline' => {'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5'},
    'holy' => {'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5'},
    'shadow' => {'spell_shadow_damage' => 'Shadow Damage', 'spell_shadow_crit' => 'Shadow Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration'},
  },
  'rogue' => {
    'base' => {'health' => 'Health', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'defenses_resilience' => 'Resilience'},
  },
  'shaman' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'elemental' => {'spell_nature_damage' => 'Nature Damage', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration'},
    'enhancement' => {'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
    'restoration' => {'spell_bonus_healing' => 'Plus Healing', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5'},
  },
  'warlock' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'spell_shadow_damage' => 'Shadow Damage', 'spell_shadow_crit' => 'Shadow Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'defenses_resilience' => 'Resilience'},
  },
  'warrior' => {
    'base' => {'health' => 'Health', 'defenses_resilience' => 'Resilience'},
    'protection' => {'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'defenses_parry' => 'Parry %', 'defenses_block' => 'Block %'},
    'fury' => {'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
    'arms' => {'melee_mainhand_damage' => 'Weapon Damage', 'melee_mainhand_damage_dps' => 'Weapon DPS', 'melee_mainhand_speed' => 'Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
  },
}
