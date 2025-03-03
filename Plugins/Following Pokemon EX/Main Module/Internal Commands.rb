module FollowingPkmn
  #-----------------------------------------------------------------------------
  @@can_refresh = false
  #-----------------------------------------------------------------------------
  # Checks if the Following Pokemon is active and following the player
  #-----------------------------------------------------------------------------
  def self.active?; return @@can_refresh; end
  #-----------------------------------------------------------------------------
  # Checks whether Following Pokemon data should be accessed or no
  #-----------------------------------------------------------------------------
  def self.can_check?
    return false if !$game_temp || !$PokemonGlobal || !$player
    return false if !$game_temp.respond_to?(:followers) || !$game_temp.followers
    return false if !$PokemonGlobal.respond_to?(:followers) || !$PokemonGlobal.followers
    return false if !$player.respond_to?(:party) || !$player.party
    return true
  end
  #-----------------------------------------------------------------------------
  # Refresh Following Pokemon's visibility when Following the player
  #-----------------------------------------------------------------------------
  def self.refresh_internal
    if !FollowingPkmn.can_check? || !FollowingPkmn.get || !$PokemonGlobal.follower_toggled
      @@can_refresh = false
      return
    end
    refresh = false
    first_pkmn = FollowingPkmn.get_pokemon
    if first_pkmn
      refresh = EventHandlers.trigger_2(:following_pkmn_appear, first_pkmn)
      refresh = true if refresh == -1
    end
    @@can_refresh = refresh
  end
  #-----------------------------------------------------------------------------
  # Raises The Current Following Pokemon's Happiness by 3-5 and
  # checks for hold item
  #-----------------------------------------------------------------------------
  def self.increase_time
    return if !FollowingPkmn.can_check?
    $PokemonGlobal.time_taken += 1
    friendship_time = FollowingPkmn::FRIENDSHIP_TIME_TAKEN * Graphics.frame_rate
    item_time = FollowingPkmn::ITEM_TIME_TAKEN * Graphics.frame_rate
    FollowingPkmn.get_pokemon&.changeHappiness("levelup") if ($PokemonGlobal.time_taken % friendship_time) == 0
    $PokemonGlobal.follower_hold_item = true if ($PokemonGlobal.time_taken > item_time)
  end
  #-----------------------------------------------------------------------------
  # Script Command for Following Pokémon finding an item in the field
  #-----------------------------------------------------------------------------
  def self.item(item, playerName, quantity = 1, message = nil)
    return false if !FollowingPkmn.can_check?
    return false if !$PokemonGlobal.follower_hold_item
    pokename = FollowingPkmn.get_pokemon&.name
    message = _INTL("{2}{1} seems to be holding something...") if nil_or_empty?(message)
    pbMessage(_INTL(message, playerName, pokename))
    item = GameData::Item.get(item)
    return false if !item || quantity < 1
    itemname = (quantity > 1) ? item.name_plural : item.name
    pocket = item.pocket
    move   = item.move
    if $bag.add(item, quantity)   # If item can be picked up
      meName = (item.is_key_item?) ? "Key item get" : "Item get"
      if item == :LEFTOVERS
        pbMessage(_INTL("\\me[{1}]{4}{3} found some \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename, playerName))
      elsif item == :DNASPLICERS
        pbMessage(_INTL("\\me[{1}]{4}{3} found \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename, playerName))
      elsif item.is_machine?   # TM or HM
        pbMessage(_INTL("\\me[{1}]{5}{4} found \\c[1]{2} {3}\\c[0]!\\wtnp[30]", meName, itemname, GameData::Move.get(move).name, pokename, playerName))
      elsif quantity>1
        pbMessage(_INTL("\\me[{1}]{5}{4} found {2} \\c[1]{3}\\c[0]!\\wtnp[30]", meName, quantity, itemname, pokename, playerName))
      elsif itemname.starts_with_vowel?
        pbMessage(_INTL("\\me[{1}]{4}{3} found an \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename, playerName))
      else
        pbMessage(_INTL("\\me[{1}]{4}{3} found a \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename, playerName))
      end
      pbMessage(_INTL("You put the {1} away\\nin the <icon=bagPocket{2}>\\c[1]{3} Pocket\\c[0].",
        itemname, pocket, PokemonBag.pocket_names[pocket - 1]))
      #pbMessage(_INTL("You put the {1} in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] pocket.",
      #  itemname, pocket, PokemonBag.pocket_names[pocket - 1]))
      #doesn't work yet
      $PokemonGlobal.follower_hold_item = false
      $PokemonGlobal.time_taken         = 0
      return true
    end
    # Can't add the item
    if item == :LEFTOVERS
      pbMessage(_INTL("{3}{1} found some \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname, playerName))
    elsif item == :DNASPLICERS
      pbMessage(_INTL("{3}{1} found \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname, playerName))
    elsif item.is_machine?   # TM or HM
      pbMessage(_INTL("{4}{1} found \\c[1]{2} {3}\\c[0]!\\wtnp[30]", pokename, itemname, GameData::Move.get(move).name, playerName))
    elsif quantity>1
      pbMessage(_INTL("{4}{1} found {2} \\c[1]{3}\\c[0]!\\wtnp[30]", pokename, quantity, itemname, playerName))
    elsif itemname.starts_with_vowel?
      pbMessage(_INTL("{3}{1} found an \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname, playerName))
    else
      pbMessage(_INTL("{3}{1} found a \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname, playerName))
    end
    pbMessage(_INTL("But your Bag is full..."))
    return false
  end
  #-----------------------------------------------------------------------------
  # Check if the Following Pokemon can be spoken to, or not
  #-----------------------------------------------------------------------------
  def self.can_talk?(interact = false)
    return false if !FollowingPkmn.can_check?
    return false if !$game_temp || $game_temp.in_battle || $game_temp.in_menu
    facing = pbFacingTile
    if !FollowingPkmn.active? || !$game_map.passable?(facing[1], facing[2], $game_player.direction, $game_player)
      if interact
        $game_player.straighten
        EventHandlers.trigger(:on_player_interact)
      end
      return false
    end
    return true
  end
  #-----------------------------------------------------------------------------
end
