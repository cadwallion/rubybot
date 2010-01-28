class ArmoryModule
  def self.domain_check(arg)
    if arg =~ /eu/i
      return "eu.wowarmory.com"
    elsif arg =~ /kr/i
      return "kr.wowarmory.com"
    elsif arg =~ /cn/i
      return "cn.wowarmory.com"
    else
      return "www.wowarmory.com"
    end
  end
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
  def self.greed(args, event)
    if args =~ /^(us|eu|kr|cn) (.*) (.*)$/i
      domain = domain_check($1)
      return get_greed(domain, $2, $3)
    end
    return false
  end
  def self.char_info(args, event)
    if args =~ /^(us|eu|kr|cn) (.*) (.*)$/i
      domain = domain_check($1)
      return get_stats(domain, $2, $3, $1)
    end
    return false
  end
  def self.show_points(args, event)
    value = args.split
    return "#{value[1]} rating = " + get_points(value[0], value[1])
  end
  def self.armory_link(domain, realm, charactername, country)
    tinyurl = mktinyurl(URI.parse("http://#{domain}/character-sheet.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}").to_s)
    whrealm = realm.gsub(/ /,"-").gsub(/\+/, "-").gsub(/'/, "")
    whtinyurl = mktinyurl(URI.parse("http://profiler.wowhead.com/?profile=#{URI.encode(country.downcase)}.#{URI.encode(whrealm.downcase)}.#{URI.encode(charactername.downcase)}").to_s)
    return "#{charactername.capitalize}'s Wowhead Profile: #{whtinyurl} - WowArmory Profile: #{tinyurl}"
    return false
  end
  def self.buffinfo(args, event)
    value = args.split(' ', 4)
    domain = domain_check(value[0])
    return get_buff_info(domain, value[1], value[2], value[3])
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
    return output
  end
  
  def self.get_greed(domain, realm, charactername)
    begin
      url = URI.parse("http://#{domain}/character-statistics.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}&c=130").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        return "#{charactername.capitalize}: Error downloading armory profile, armory may be down" unless xmldoc
        armoryinfo = (REXML::Document.new xmldoc).root
        if armoryinfo and armoryinfo.elements['/category/category'] and armoryinfo.elements["/category/category[@name='Gear']"]
          greed = armoryinfo.elements["/category/category[@name='Gear']/statistic[@name='Greed rolls made on loot']"].attributes['quantity'].to_i
          need = armoryinfo.elements["/category/category[@name='Gear']/statistic[@name='Need rolls made on loot']"].attributes['quantity'].to_i
          return "#{charactername.capitalize} has never rolled need on an item." if need < 1
          ratio = ((need.to_f / (greed + need)) * 100).to_i
          output = case ratio
            when 0 .. 5: "You are a nice person, maybe too nice. (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            when 5 .. 15: "You are not a greedy person. (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            when 15 .. 30: "You should watch it, you're getting needy. (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            when 30 .. 50: "Wow I'm glad you aren't my girlfriend/boyfriend. (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            when 50 .. 75: "Do you understand the meaning of 'need'? (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            when 75 .. 100: "Wow you need to leave loot for everyone else! (#{ratio}% needs - #{need} needs, #{greed} greeds)"
            else "Unknown greed level"
          end
          return "#{charactername.capitalize}: #{output}"
        else
          return "#{charactername.capitalize}: Error getting data"
      end
    rescue => err
      log_error(err)
    end
    return nil
  end
  
  def self.mktinyurl(url)
    begin
      url = URI.parse("http://tinyurl.com/api-create.php?url=#{url}").to_s
      tinyurl = RemoteRequest.new("get").read(url)
      if tinyurl =~ /^http:\/\/tinyurl\.com\/.*/
        return tinyurl
      else
        return false
      end
    rescue => err
      log_error(err)
    end
    return false
  end
  
  def self.get_stats(domain, realm, charactername, country)
    begin
      url = URI.parse("http://#{domain}/character-sheet.xml?r=#{URI.encode(realm)}&n=#{URI.encode(charactername)}").to_s
      xmldoc = RemoteRequest.new("get").read(url)
        return "#{charactername.capitalize}: Error downloading armory profile, armory may be down" unless xmldoc
        armoryinfo = (REXML::Document.new xmldoc).root
        if armoryinfo and armoryinfo.elements['/page/characterInfo/character'] and armoryinfo.elements['/page/characterInfo/character'].attributes.any? and armoryinfo.elements['/page/characterInfo/characterTab']
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
            'talents_1' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpecs/talentSpec[@active="1"]'].attributes["treeOne"],
            'talents_2' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpecs/talentSpec[@active="1"]'].attributes["treeTwo"],
            'talents_3' => armoryinfo.elements['/page/characterInfo/characterTab/talentSpecs/talentSpec[@active="1"]'].attributes["treeThree"],
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
            'melee_offhand_damage' => armoryinfo.elements["/page/characterInfo/characterTab/items/item[@slot='16']"].nil? ? nil : armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["min"]+"-"+armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["max"],
            'melee_mainhand_damage_dps' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandDamage'].attributes["dps"],
            'melee_offhand_damage_dps' => armoryinfo.elements["/page/characterInfo/characterTab/items/item[@slot='16']"].nil? ? nil : armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandDamage'].attributes["dps"],
            'melee_mainhand_speed' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandSpeed'].attributes["value"],
            'melee_offhand_speed' => armoryinfo.elements["/page/characterInfo/characterTab/items/item[@slot='16']"].nil? ? nil : armoryinfo.elements['/page/characterInfo/characterTab/melee/offHandSpeed'].attributes["value"],
            'melee_power' => armoryinfo.elements['/page/characterInfo/characterTab/melee/power'].attributes["effective"],
            'melee_hitrating' => armoryinfo.elements['/page/characterInfo/characterTab/melee/hitRating'].attributes["increasedHitPercent"],
            'melee_crit' => armoryinfo.elements['/page/characterInfo/characterTab/melee/critChance'].attributes["percent"],
            'melee_haste' => armoryinfo.elements['/page/characterInfo/characterTab/melee/mainHandSpeed'].attributes["hastePercent"],
            #range stats
            'range_skill' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/weaponSkill'].attributes["value"],
            'range_damage' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["min"]+"-"+armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["max"],
            'range_damage_dps' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/damage'].attributes["dps"],
            'range_speed' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/speed'].attributes["value"],
            'range_power' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/power'].attributes["effective"],
            'range_hitrating' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/hitRating'].attributes["increasedHitPercent"],
            'range_crit' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/critChance'].attributes["percent"],
            'range_haste' => armoryinfo.elements['/page/characterInfo/characterTab/ranged/speed'].attributes["hastePercent"],
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
            'spell_haste' => armoryinfo.elements['/page/characterInfo/characterTab/spell/hasteRating'].attributes["hastePercent"],
            #defenses
            'defenses_armor' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/armor'].attributes["effective"],
            'defenses_armor_perc' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/armor'].attributes["percent"],
            'defenses_defense' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/defense'].attributes["value"] +"+"+ armoryinfo.elements['/page/characterInfo/characterTab/defenses/defense'].attributes["plusDefense"],
            'defenses_dodge' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/dodge'].attributes["percent"],
            'defenses_parry' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/parry'].attributes["percent"],
            'defenses_block' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/block'].attributes["percent"],
            'defenses_resilience' => armoryinfo.elements['/page/characterInfo/characterTab/defenses/resilience'].attributes["value"],
          }
          if (@@class_show_stats.has_key?(character["characterclass"].downcase))
            spec = get_spec(character["talents_1"],character["talents_2"],character["talents_3"],character["characterclass"].downcase)
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
              unless character[statkey].nil? or character[statkey] == ""
                output = output + " #{stat}: #{character[statkey]};"
              end
            end
            armory_links = armory_link(domain, realm, charactername, country)
            if armory_links
              output += " #{armory_links}"
            end
            return output
          else
            return "#{charactername.capitalize}: Sorry, I don't know how to handle your class yet."
          end
        else
          return "Character #{charactername}, not found."
        end
    rescue => err
      log_error(err)
    end
    return nil
  end
end

@@class_talent_trees = {
  'death knight' => ['blood', 'frost', 'unholy'],
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
  'death knight' => {
    'base' => {'health' => 'Health', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'defenses_resilience' => 'Resilience', 'melee_haste' => 'Melee Haste %', 'defenses_armor' => 'Armor', 'defenses_armor_perc' => 'Armor Reduction %', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'defenses_parry' => 'Parry %'},
  },
  'druid' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'balance' => {'spell_arcane_damage' => 'Arcane Damage', 'spell_arcane_crit' => 'Arcane Crit %', 'spell_nature_damage' => 'Nature Damage', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'spell_haste' => 'Spell Haste %'},
    'feral' => {'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'melee_haste' => 'Melee Haste %', 'defenses_armor_perc' => 'Armor Reduction %'},
    'restoration' => {'spell_bonus_healing' => 'Plus Healing', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_haste' => 'Spell Haste %'},
  },
  'hunter' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'range_power' => 'Ranged Attack Power', 'range_damage' => 'Ranged Damage', 'range_speed' => 'Ranged Attack Speed', 'range_damage_dps' => 'Ranged DPS', 'range_hitrating' => 'Ranged Hit %', 'range_crit' => 'Ranged Crit %', 'defenses_resilience' => 'Resilience', 'spell_manaregen' => 'MP5', 'range_haste' => 'Ranged Haste %'},
  },
  'mage' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'defenses_resilience' => 'Resilience', 'spell_haste' => 'Spell Haste %'},
    'arcane' => {'spell_arcane_damage' => 'Arcane Damage', 'spell_arcane_crit' => 'Arcane Crit %'},
    'fire' => {'spell_fire_damage' => 'Fire Damage', 'spell_fire_crit' => 'Fire Crit %'},
    'frost' => {'spell_frost_damage' => 'Frost Damage', 'spell_frost_crit' => 'Frost Crit %'},
  },
  'paladin' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'holy' => {'intellect' => 'Intellect', 'spell_holy_damage' => 'Holy Damage', 'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5', 'spell_haste' => 'Spell Haste %'},  
    'protection' => {'spell_holy_damage' => 'Holy Damage', 'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'defenses_parry' => 'Parry %', 'defenses_block' => 'Block %', 'melee_haste' => 'Melee Haste %', 'defenses_armor_perc' => 'Armor Reduction %'},
    'retribution' => {'spell_holy_damage' => 'Holy Damage', 'melee_expertise' => 'Expertise %', 'melee_mainhand_damage' => 'Weapon Damage', 'melee_mainhand_damage_dps' => 'Weapon DPS', 'melee_mainhand_speed' => 'Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'melee_haste' => 'Melee Haste %'},
  },
  'priest' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience', 'spell_haste' => 'Spell Haste %'},
    'discipline' => {'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5'},
    'holy' => {'spell_bonus_healing' => 'Plus Healing', 'spell_holy_crit' => 'Holy Crit %', 'spell_manaregen' => 'MP5'},
    'shadow' => {'spell_shadow_damage' => 'Shadow Damage', 'spell_shadow_crit' => 'Shadow Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration'},
  },
  'rogue' => {
    'base' => {'health' => 'Health', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'defenses_resilience' => 'Resilience', 'melee_haste' => 'Melee Haste %'},
  },
  'shaman' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'defenses_resilience' => 'Resilience'},
    'elemental' => {'spell_nature_damage' => 'Nature Damage', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'spell_haste' => 'Spell Haste %'},
    'enhancement' => {'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit', 'melee_haste' => 'Melee Haste %'},
    'restoration' => {'spell_bonus_healing' => 'Plus Healing', 'spell_nature_crit' => 'Nature Crit %', 'spell_manaregen' => 'MP5', 'spell_haste' => 'Spell Haste %'},
  },
  'warlock' => {
    'base' => {'health' => 'Health', 'mana' => 'Mana', 'spell_shadow_damage' => 'Shadow Damage', 'spell_shadow_crit' => 'Shadow Crit %', 'spell_manaregen' => 'MP5', 'spell_hitrating' => 'Spell Hit %', 'spell_penetration' => 'Spell Penetration', 'defenses_resilience' => 'Resilience', 'spell_fire_damage' => 'Fire Damage', 'spell_fire_crit' => 'Fire Crit %', 'spell_haste' => 'Spell Haste %'},
  },
  'warrior' => {
    'base' => {'health' => 'Health', 'defenses_resilience' => 'Resilience', 'melee_haste' => 'Melee Haste %'},
    'protection' => {'defenses_armor' => 'Armor', 'defenses_defense' => 'Defense', 'defenses_dodge' => 'Dodge %', 'defenses_parry' => 'Parry %', 'defenses_block' => 'Block %', 'defenses_armor_perc' => 'Armor Reduction %'},
    'fury' => {'melee_mainhand_damage' => 'Mainhand Weapon Damage', 'melee_mainhand_damage_dps' => 'Mainhand Weapon DPS', 'melee_mainhand_speed' => 'Mainhand Weapon Speed', 'melee_offhand_damage' => 'Offhand Weapon Damage', 'melee_offhand_damage_dps' => 'Offhand Weapon DPS', 'melee_offhand_speed' => 'Offhand Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
    'arms' => {'melee_mainhand_damage' => 'Weapon Damage', 'melee_mainhand_damage_dps' => 'Weapon DPS', 'melee_mainhand_speed' => 'Weapon Speed', 'melee_power' => 'Attack Power', 'melee_hitrating' => 'Melee Hit %', 'melee_crit' => 'Melee Crit'},
  },
}
