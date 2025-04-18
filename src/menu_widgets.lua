text_default_color = 0xF7FFF7FF
text_default_border_color = 0x101008FF
text_selected_color = 0xFF0000FF
text_disabled_color = 0x999999FF

gui_box_bg_color = 0x293139FF
gui_box_outline_color = 0x840000FF

menu_y_interval = 10

function gauge_menu_item(_name, _object, _property_name, _unit, _fill_color, _default_value, _gauge_max, _subdivision_count)
  if _default_value == nil then _default_value = 0 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.player_id = _player_id
  _o.autofire_rate = 1
  _o.unit = _unit or 2
  _o.gauge_max = _gauge_max or 0
  _o.subdivision_count = _subdivision_count or 1
  _o.fill_color = _fill_color or 0x0000FFFF
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end
    gui.text(_x, _y, _prefix..self.name.." : ", _c, text_default_border_color)

    local _box_width = self.gauge_max / self.unit
    local _box_top = _y + 1
    local _box_left = _x + get_text_width("< "..self.name.." : ") - 1
    local _box_right = _box_left + _box_width
    local _box_bottom = _box_top + 4
    gui.box(_box_left, _box_top, _box_right, _box_bottom, text_default_color, text_default_border_color)
    local _content_width = self.object[self.property_name] / self.unit
    gui.box(_box_left, _box_top, _box_left + _content_width, _box_bottom, self.fill_color, 0x00000000)
    for _i = 1, self.subdivision_count - 1 do
      local _line_x = _box_left + _i * self.gauge_max / (self.subdivision_count * self.unit)
      gui.line(_line_x, _box_top, _line_x, _box_bottom, text_default_border_color)
    end

    --gui.text(_box_right + 2, _y, _suffix, _c, text_default_border_color)
    gui.text(_box_right + 2, _y, string.format(" %d/%d%s", _content_width, self.gauge_max, _suffix), _c, text_default_border_color) -- add ashtanga
  end

  function _o:left()
    self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
  end

  function _o:right()
    self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

available_characters = {
  " ",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "X",
  "Y",
  "Z",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "-",
  "_",
}

function textfield_menu_item(_name, _object, _property_name, _default_value, _max_length)
  _default_value = _default_value or ""
  _max_length = _max_length or 16
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value
  _o.max_length = _max_length
  _o.edition_index = 0
  _o.is_in_edition = false
  _o.content = {}

  function _o:sync_to_var()
    local _str = ""
    for i = 1, #self.content do
      _str = _str..available_characters[self.content[i]]
    end
    self.object[self.property_name] = _str
  end

  function _o:sync_from_var()
    self.content = {}
    for i = 1, #self.object[self.property_name] do
      local _c = self.object[self.property_name]:sub(i,i)
      for j = 1, #available_characters do
        if available_characters[j] == _c then
          table.insert(self.content, j)
          break
        end
      end
    end
  end

  function _o:crop_char_table()
    local _last_empty_index = 0
    for i = 1, #self.content do
      if self.content[i] == 1 then
        _last_empty_index = i
      else
        _last_empty_index = 0
      end
    end

    if _last_empty_index > 0 then
      for i = _last_empty_index, #self.content do
        table.remove(self.content, _last_empty_index)
      end
    end
  end

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if self.is_in_edition then
      _c =  0xFFFF00FF
    elseif _selected then
      _c = text_selected_color
    end

    local _value = self.object[self.property_name]

    if self.is_in_edition then
      local _cycle = 100
      if ((frame_number % _cycle) / _cycle) < 0.5 then
        gui.text(_x + (#self.name + 3 + #self.content - 1) * 4, _y + 2, "_", _c, text_default_border_color)
      end
    end

    gui.text(_x, _y, _prefix..self.name.." : ".._value.._suffix, _c, text_default_border_color)
  end

  function _o:left()
    if self.is_in_edition then
      self:reset()
    end
  end

  function _o:right()
    if self.is_in_edition then
      self:validate()
    end
  end

  function _o:up()
    if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] + 1
      if self.content[self.edition_index] > #available_characters then
        self.content[self.edition_index] = 1
      end
      self:sync_to_var()
      return true
    else
      return false
    end
  end

  function _o:down()
    if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] - 1
      if self.content[self.edition_index] == 0 then
        self.content[self.edition_index] = #available_characters
      end
      self:sync_to_var()
      return true
    else
      return false
    end
  end

  function _o:validate()
    if not self.is_in_edition then
      self:sync_from_var()
      if #self.content < self.max_length then
        table.insert(self.content, 1)
      end
      self.edition_index = #self.content
      self.is_in_edition = true
    else
      if self.content[self.edition_index] ~= 1 then
        if #self.content < self.max_length then
          table.insert(self.content, 1)
          self.edition_index = #self.content
        end
      end
    end
    self:sync_to_var()
  end

  function _o:reset()
    if not self.is_in_edition then
      _o.content = {}
      self.edition_index = 0
    else
      if #self.content > 1 then
        table.remove(self.content, #self.content)
        self.edition_index = #self.content
      else
        self.content[1] = 1
      end
    end
    self:sync_to_var()
  end

  function _o:cancel()
    if self.is_in_edition then
      self:crop_char_table()
      self:sync_to_var()
      self.is_in_edition = false
    end
  end

  function _o:legend()
    if self.is_in_edition then
      return "LP/Right: Next   MP/Left: Previous   LK: Leave edition"
    else
      return "LP: Edit   MP: Reset to default"
    end
  end

  _o:sync_from_var()
  return _o
end

function checkbox_menu_item(_name, _object, _property_name, _default_value)
  if _default_value == nil then _default_value = false end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    local _value = ""
    if self.object[self.property_name] then
      _value = "yes"
    else
      _value = "no"
    end
    gui.text(_x, _y, _prefix..self.name.." : ".._value.._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:right()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function list_menu_item(_name, _object, _property_name, _list, _default_value, _sub_list_property_to_reset, _calculate_percentage_for_trials_details_table)
  if _default_value == nil then _default_value = 1 end
  if _sub_list_property_to_reset == nil then _sub_list_property_to_reset = false end
  if _calculate_percentage_for_trials_details_table == nil then _calculate_percentage_for_trials_details_table = false end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.list = _list
  _o.default_value = _default_value
  _o.sub_list_property_to_reset = _sub_list_property_to_reset
  _o.calculate_percentage_for_trials_details_table = _calculate_percentage_for_trials_details_table

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    local _percentage = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    -- Caculate the number of trials completed
    if self.calculate_percentage_for_trials_details_table then
      -- Get all the trials for the current selected character, then count the number of completed trials
      _total_trials = #self.calculate_percentage_for_trials_details_table[self.object[self.property_name]]
      _total_trials_completed = 0
      for i in ipairs(self.calculate_percentage_for_trials_details_table[self.object[self.property_name]]) do
        if self.calculate_percentage_for_trials_details_table[self.object[self.property_name]][i]['completed_count'] > 0 then
          _total_trials_completed = _total_trials_completed + 1
        end
      end

      _percentage = " - "..string.format("%.2f", (_total_trials_completed/_total_trials)*100).."%"
    end
    gui.text(_x, _y, _prefix..self.name.." : "..self.list[self.object[self.property_name]].._percentage.._suffix, _c, text_default_border_color)
  end

  function _o:left()
    if self.sub_list_property_to_reset then
      self.object[self.sub_list_property_to_reset] = 1
    end
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
  end

  function _o:right()
    if self.sub_list_property_to_reset then
      self.object[self.sub_list_property_to_reset] = 1
    end
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

--- This menu item is used to extract a 'sublist' from a table of values.
--- It will will display the value of the property and store the index of the subtable
---
--- 
--- @param _name string: The name of the menu item, eg: 'Character'
--- @param _object table: The table that stores the properties, eg: 'trial_settings'
--- @param _property_name string: The property to modify in the object, eg: 'sublist_index'
--- @param _sub_list table: The sublist that will be to lookup the sub_list_property, eg: trial_data
--- @param _sub_list_index_name string: The property to use for the sub_list index, eg: 'character_selected'
--- @param _sub_list_property string: The property to display in the sublist, eg: 'char'
--- @param _default_value? integer: The default index of the sublist to look at, eg: 1
function sub_list_menu_item(_name, _object, _property_name, _sub_list, _sub_list_index_name, _sub_list_property, _default_value)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.sub_list = _sub_list
  _o.sub_list_index_name = _sub_list_index_name
  _o.sub_list_property = _sub_list_property
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    gui.text(_x, _y, _prefix..self.name.." : "..self.sub_list[self.object[self.sub_list_index_name]][self.object[self.property_name]][self.sub_list_property].._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.sub_list[self.object[self.sub_list_index_name]]
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.sub_list[self.object[self.sub_list_index_name]] then
      self.object[self.property_name] = 1
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

--- This menu item is used to display a single line of text
--- It can only span a single line, or it will extend past the menu boarder.
--- You can use \n linebreaks to split the text into multiple lines.
---
--- @param _name string: The name of the menu item, eg: 'Trial description'
--- @param _object table: The table that stores the text, eg: 'trial_settings'
--- @param _property_name string: The property to read the text from eg: 'description'
--- @param _default_value? string: The default value to display if the property is nil, eg: 'No description'
function text_menu_item(_name, _object, _property_name, _default_value)
  if _default_value == nil then _default_value = "" end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = ""
      _suffix = ""
    end
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.object[self.property_name]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
  end

  function _o:right()
  end

  function _o:reset()
  end

  function _o:legend()
    return ""
  end

  return _o
end

--- This menu item is used to display a single line of text from a sublist.
--- It can only span a single line, or it will extend past the menu boarder.
--- You can use \n linebreaks to split the text into multiple lines.
--- 
--- @param _name string: The name of the menu item, eg: 'Trial description'
--- @param _object table: The table that stores index of the sub_list, eg: 'trial_settings'
--- @param _property_name string: The property to read the index of the sublist from eg: 'character_selected'
--- @param _sub_list_property_name string: The name of the property to read the sublist index from, eg: 'trial_selected'
--- @param _sub_list table: The sublist that will be to lookup the sub_list_property, eg: trial_data
--- @param _sub_list_property string: The property to display in the sublist, eg: 'description'
--- @param _default_value? string: The default value to display if the property is nil, eg: 'No description'
function sub_text_menu_item(_name, _object, _property_name, _sub_list_property_name, _sub_list, _sub_list_property, _default_value)
  if _default_value == nil then _default_value = "" end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.sub_list_property_name = _sub_list_property_name
  _o.sub_list = _sub_list
  _o.sub_list_property = _sub_list_property
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = ""
      _suffix = ""
    end
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.sub_list[self.object[self.property_name]][self.object[self.sub_list_property_name]][self.sub_list_property]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
  end

  function _o:right()
  end

  function _o:reset()
  end

  function _o:legend()
    return ""
  end

  return _o
end

--- This creates an empty menu entry, used for splitting sections of the menu
function empty_menu_item()
  local _o = {}
  _o.empty_item = true

  function _o:draw(_x, _y, _selected)
    gui.text(_x, _y, "", text_default_color, text_default_border_color)
  end

  function _o:left()
  end

  function _o:right()
  end

  function _o:reset()
  end

  function _o:legend()
    return ""
  end

  return _o
end

--- This function creates a doubly circular linked list from a table of values.
--- 
--- @param values table: The table of values to create the list from.
function toDoublyCircularList(values)
  local circular = {}
  local n = #values

  -- Create nodes
  for i = 1, n do
      circular[i] = {
          value = values[i],
          next = nil,
          prev = nil,
          index = i
      }
  end

  -- Link nodes in both directions
  for i = 1, n do
      circular[i].next = circular[(i % n) + 1]
      circular[i].prev = circular[(i - 2 + n) % n + 1]
  end

  local head = circular[1]
  head._length = n -- store the size in the head for reference
  return head
end

--- This function retrieves a node at a specific index in a doubly circular linked list.
--- 
--- @param head table: The head of the circular linked list.
--- @param index integer: The index of the node to retrieve.
function getNodeAt(head, index)
  local len = head._length
  if len == 0 then return nil end

  -- Normalize index to 1-based circular index
  index = ((index - 1) % len) + 1

  local current = head
  while current.index ~= index do
      current = current.next
  end
  return current
end

--- This creates a scrollable menu entry, used for scrolling through a list of values.<br>
--- For example, if _table contains 5 characters, _displayed_items is 5, and _default_value is 3, then we display:<br>
--- 
--- ...Character 1<br>
--- Character 2<br>
--- <Character 3><br>
--- Character 4<br>
--- Character 5...<br>
--- 
--- If _table contains 3 characters, and _displayed_items is 5, and _default_value is 1, then we display:
--- 
--- ...Character 2<br>
--- Character 3<br>
--- <Character 1><br>
--- Character 2<br>
--- Character 3...<br>
--- 
--- @param _object table: The table that stores the property, eg: 'trial_settings'
--- @param _property_name string: The property that stores the current selected item, eg: 'trial_selected'
--- @param _table table: The table that contains the list of items to display, eg: characters
--- @param _displayed_items integer: The number of items to display in the menu, must be odd, eg: 5
--- @param _default_value? integer: The default value to display if the property is nil, eg: 1
function scrollable_trial_menu(_object, _property_name, _table, _displayed_items, _default_value)
  if _default_value == nil then _default_value = 1 end
  if (_displayed_items % 2 == 0) then
    error("scrollable_trial_menu requires an odd number of displayed items, got ".._displayed_items)
  end
  local _o = {}
  _o.object = _object
  _o.property_name = _property_name
  _o.table = _table
  _o.displayed_items = _displayed_items
  _o.default_value = _default_value
  _o.y_padding = (_displayed_items -1) * menu_y_interval


  function _o:draw(_x,_y, _selected)
    local _c = text_default_color
    if _selected then
      _c = text_selected_color
    end

    local _current_index = self.object[self.property_name]
    local _middle_index = (self.displayed_items +1) / 2
    local circular_list = toDoublyCircularList(_table)

    _y = _y - menu_y_interval

    for i = 1, self.displayed_items do
      _node = getNodeAt(circular_list, _current_index - (i - _middle_index))
      _y = _y + menu_y_interval
      
      if i == _middle_index then
        gui.text(_x, _y, "<".._node.value..">", _c, text_default_border_color)

      else
        gui.text(_x, _y, _node.value, text_default_color, text_default_border_color)
      end
    end
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.table then
      self.object[self.property_name] = 1
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < 1 then
      self.object[self.property_name] = #self.table
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

--- This creates a sub scrollable menu entry, used for scrolling through a list of values.<br>
--- TODO: Currently hardcoded to look for completed status. Need to template the string to display
--- 
--- @param _object table: The table that stores the properties, eg: 'trial_settings'
--- @param _property_name string: The property that stores the current selected item, eg: 'trial_selected'
--- @param _sub_property_name string: The property that stores the index of the sublist, eg: 'character_selected'
--- @param _table table: The table that contains the sublist of items to display, eg: trial_details
--- @param _sub_property_value_name string: The name of the sub property to display
--- @param _displayed_items integer: The number of items to display in the menu, must be odd, eg: 5
--- @param _default_value? integer: The default value to display if the property is nil, eg: 1
function sub_scrollable_trial_menu(_object, _property_name, _sub_property_name, _table, _sub_property_value_name, _displayed_items, _default_value)
  if _default_value == nil then _default_value = 1 end
  if (_displayed_items % 2 == 0) then
    error("scrollable_trial_menu requires an odd number of displayed items, got ".._displayed_items)
  end
  local _o = {}
  _o.object = _object
  _o.property_name = _property_name
  _o.sub_property_name = _sub_property_name
  _o.sub_property_value_name = _sub_property_value_name
  _o.table = _table
  _o.displayed_items = _displayed_items
  _o.default_value = _default_value
  _o.y_padding = (_displayed_items -1) * menu_y_interval


  function _o:draw(_x,_y, _selected)
    local _c = text_default_color
    if _selected then
      _c = text_selected_color
    end

    local _current_index = self.object[self.property_name]
    local _middle_index = (self.displayed_items +1) / 2
    local circular_list = toDoublyCircularList(self.table[self.object[self.sub_property_name]])

    _y = _y - menu_y_interval

    for i = 1, self.displayed_items do
      _node = getNodeAt(circular_list, _current_index - (i - _middle_index))
      if _node.value['completed_count'] > 4 then
        _completed_mark = "S"
      elseif _node.value['completed_count'] > 0 then
        _completed_mark = "X"
      else
        _completed_mark = " "
      end
      _y = _y + menu_y_interval
      
      if i == _middle_index then
        gui.text(_x, _y, "< [".._completed_mark.."] ".._node.value[self.sub_property_value_name]..">", _c, text_default_border_color)

      else
        gui.text(_x, _y, "[".._completed_mark.."] ".._node.value[self.sub_property_value_name], text_default_color, text_default_border_color)
      end
    end
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.table[self.object[self.sub_property_name]] then
      self.object[self.property_name] = 1
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < 1 then
      self.object[self.property_name] = #self.table[self.object[self.sub_property_name]]
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function integer_menu_item(_name, _object, _property_name, _min, _max, _loop, _default_value, _autofire_rate)
  if _default_value == nil then _default_value = _min end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.min = _min
  _o.max = _max
  _o.loop = _loop
  _o.default_value = _default_value
  _o.autofire_rate = _autofire_rate

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.object[self.property_name]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < self.min then
      if self.loop then
        self.object[self.property_name] = self.max
      else
        self.object[self.property_name] = self.min
      end
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > self.max then
      if self.loop then
        self.object[self.property_name] = self.min
      else
        self.object[self.property_name] = self.max
      end
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function map_menu_item(_name, _object, _property_name, _map_object, _map_property)
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.map_object = _map_object
  _o.map_property = _map_property

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    local _str = string.format("%s%s : %s%s", _prefix, self.name, self.object[self.property_name], _suffix)
    gui.text(_x, _y, _str, _c, text_default_border_color)
  end

  function _o:left()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _key == self.object[self.property_name] then
          self.object[self.property_name] = _previous_key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function _o:right()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
        return
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _previous_key == self.object[self.property_name] then
          self.object[self.property_name] = _key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function _o:reset()
    self.object[self.property_name] = ""
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function button_menu_item(_name, _validate_function)
  local _o = {}
  _o.name = _name
  _o.validate_function = _validate_function
  _o.last_frame_validated = 0

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    if _selected then
      _c = text_selected_color

      if self.last_frame_validated > frame_number then
        self.last_frame_validated = 0
      end

      if (frame_number - self.last_frame_validated < 5 ) then
        _c = 0xFFFF00FF
      end
    end

    gui.text(_x, _y,self.name, _c, text_default_border_color)
  end

  function _o:validate()
    self.last_frame_validated = frame_number
    if self.validate_function then
      self.validate_function()
    end
  end

  function _o:legend()
    return "LP: Validate"
  end

  return _o
end

-- # Menus
menu_stack = {}

function menu_stack_push(_menu)
  table.insert(menu_stack, _menu)
end

function menu_stack_pop(_menu)
  for _i, _m in ipairs(menu_stack) do
    if _m == _menu then
      table.remove(menu_stack, _i)
      break
    end
  end
end

function menu_stack_top()
  return menu_stack[#menu_stack]
end

function menu_stack_clear()
  menu_stack = {}
end

function menu_stack_update(_input)
  if #menu_stack == 0 then
    return
  end

  local _last_menu = menu_stack[#menu_stack]
  _last_menu:update(_input)
end

function menu_stack_draw()
  for _i, _menu in ipairs(menu_stack) do
    _menu:draw()
  end
end

function make_multitab_menu(_left, _top, _right, _bottom, _content, _on_toggle_entry, _additional_draw)
  local _m = {}
  _m.left = _left
  _m.top = _top
  _m.right = _right
  _m.bottom = _bottom
  _m.content = _content

  _m.is_main_menu_selected = true
  _m.main_menu_selected_index = 1
  _m.sub_menu_selected_index = 1

  _m.on_toggle_entry = _on_toggle_entry
  _m.additional_draw = _additional_draw

  function _m:update(_input)
    multitab_menu_update(self, _input)
  end

  function _m:draw()
    multitab_menu_draw(self)
  end

  function _m:current_entry()
    if self.is_main_menu_selected then
      return nil
    else
      return self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]
    end
  end

  return _m
end

function multitab_menu_update(_menu, _input)

  if _input.down then
    repeat
      if _menu.is_main_menu_selected then
        _menu.is_main_menu_selected = false
        _menu.sub_menu_selected_index = 1
      else
        if _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index + 1] and _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index + 1] ["empty_item"] then
          _menu.sub_menu_selected_index = _menu.sub_menu_selected_index + 2
        else
          _menu.sub_menu_selected_index = _menu.sub_menu_selected_index + 1
        end
        if _menu.sub_menu_selected_index > #_menu.content[_menu.main_menu_selected_index].entries then
          _menu.is_main_menu_selected = true
        end
      end
    until (
      _menu.is_main_menu_selected or
      _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil or
      not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled()
    )
  end

  if _input.up then
    repeat
      if _menu.is_main_menu_selected then
        _menu.is_main_menu_selected = false
        _menu.sub_menu_selected_index = #_menu.content[_menu.main_menu_selected_index].entries
      else
        if _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index - 1] and _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index - 1] ["empty_item"] then
          _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 2
        else
          _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 1
        end
        if _menu.sub_menu_selected_index <= 0 then
          _menu.is_main_menu_selected = true
        end
      end
    until (
      _menu.is_main_menu_selected or
      _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil or
      not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled()
    )
  end

  local _current_entry = _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index]

  if _input.left then
    if _menu.is_main_menu_selected then
      _menu.main_menu_selected_index = _menu.main_menu_selected_index - 1
      if _menu.main_menu_selected_index == 0 then
        _menu.main_menu_selected_index = #_menu.content
      end
    elseif _current_entry ~= nil then
      if _current_entry.left ~= nil then
        _current_entry:left()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.right then
    if _menu.is_main_menu_selected then
      _menu.main_menu_selected_index = _menu.main_menu_selected_index + 1
      if _menu.main_menu_selected_index > #_menu.content then
        _menu.main_menu_selected_index = 1
      end
    elseif _current_entry ~= nil then
      if _current_entry.right ~= nil then
        _current_entry:right()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.validate then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.validate then
        _current_entry:validate()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.reset then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.reset then
        _current_entry:reset()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.cancel then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.cancel then
        _current_entry:cancel()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end
end

function multitab_menu_draw(_menu)
  gui.box(_menu.left, _menu.top, _menu.right, _menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local _bar_x = _menu.left + 10
  local _bar_y = _menu.top + 6
  local _base_offset = 0

  for i = 1, #_menu.content do
    local _offset = 0
    local _c = text_disabled_color
    local _t = _menu.content[i].name
    if _menu.is_main_menu_selected and i == _menu.main_menu_selected_index then
      _t = "< ".._t.." >"
      _c = text_selected_color
    elseif i == _menu.main_menu_selected_index then
      _c = text_default_color
      _offset = 8
    else
      _offset = 8
    end
    gui.text(_bar_x + _offset + _base_offset, _bar_y, _t, _c, text_default_border_color)
    _base_offset = _base_offset + (#_menu.content[i].name + 5) * 4
  end

  local _menu_x = _menu.left + 10
  local _menu_y = _menu.top + 23
  local _draw_index = 0
  local _is_focused = _menu == menu_stack_top()
  local _y_padding = 0
  for i = 1, #_menu.content[_menu.main_menu_selected_index].entries do
    if _menu.content[_menu.main_menu_selected_index].entries[i].is_disabled == nil or not _menu.content[_menu.main_menu_selected_index].entries[i].is_disabled() then
      if i > 1 and _menu.content[_menu.main_menu_selected_index].entries[i-1]["y_padding"] then
        _y_padding = _y_padding + _menu.content[_menu.main_menu_selected_index].entries[i-1]["y_padding"]
      end
      _menu.content[_menu.main_menu_selected_index].entries[i]:draw(_menu_x, _menu_y + _y_padding + menu_y_interval * _draw_index, not _menu.is_main_menu_selected and _is_focused and _menu.sub_menu_selected_index == i)
      _draw_index = _draw_index + 1
    end
  end

  if not _menu.is_main_menu_selected then
    if _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].legend then
      -- ��default�\���ʒu
      gui.text(_menu_x + 220, _menu.bottom - 12, _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index]:legend(), text_disabled_color, text_default_border_color)
    end
  end

  if _menu.additional_draw ~= nil then
    _menu.additional_draw(_menu)
  end

end

function make_menu(_left, _top, _right, _bottom, _content, _on_toggle_entry, _draw_legend)
  local _m = {}
  _m.left = _left
  _m.top = _top
  _m.right = _right
  _m.bottom = _bottom
  _m.content = _content

  _m.selected_index = 1
  _m.on_toggle_entry = _on_toggle_entry
  if _draw_legend ~= nil then
    _m.draw_legend = _draw_legend
  else
    _m.draw_legend = true
  end

  function _m:update(_input)
    menu_update(self, _input)
  end

  function _m:draw()
    menu_draw(self)
  end

  function _m:current_entry()
    return self.content[self.selected_index]
  end

  return _m
end

function menu_update(_menu, _input)

  if _input.up then
    if _menu.content[_menu.selected_index].is_in_edition then
      _menu.content[_menu.selected_index]:up()
    else
      repeat
        if _menu.content[_menu.selected_index - 1] and _menu.content[_menu.selected_index - 1]["empty_item"] then
          _menu.selected_index = _menu.selected_index - 2
        else
          _menu.selected_index = _menu.selected_index - 1
        end
        if _menu.selected_index <= 0 then
          _menu.selected_index = #_menu.content
        end
      until _menu.content[_menu.selected_index].is_disabled == nil or not _menu.content[_menu.selected_index].is_disabled()
    end
  end

  if _input.down then
    if _menu.content[_menu.selected_index].is_in_edition then
      _menu.content[_menu.selected_index]:down()
    else
      repeat
        if _menu.content[_menu.selected_index +1 ] and _menu.content[_menu.selected_index + 1]["empty_item"] then
          _menu.selected_index = _menu.selected_index + 2
        else
          _menu.selected_index = _menu.selected_index + 1
        end
        if _menu.selected_index >= #_menu.content + 1 then
          _menu.selected_index = 1
        end
      until _menu.content[_menu.selected_index].is_disabled == nil or not _menu.content[_menu.selected_index].is_disabled()
    end
  end

  _current_entry = _menu.content[_menu.selected_index]

  if _input.left then
    if _current_entry.left then
      _current_entry:left()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.right then
    if _current_entry.right then
      _current_entry:right()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.validate then
    if _current_entry.validate then
      _current_entry:validate()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.reset then
    if _current_entry.reset then
      _current_entry:reset()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.cancel then
    if _current_entry.cancel then
      _current_entry:cancel()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end
end

function menu_draw(_menu)
  gui.box(_menu.left, _menu.top, _menu.right, _menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local _menu_x = _menu.left + 10
  local _menu_y = _menu.top + 9
  local _draw_index = 0

  for i = 1, #_menu.content do
    if _menu.content[i].is_disabled == nil or not _menu.content[i].is_disabled() then
      _menu.content[i]:draw(_menu_x, _menu_y + menu_y_interval * _draw_index, _menu.selected_index == i)
      _draw_index = _draw_index + 1
    end
  end

  if _menu.draw_legend then
    if _menu.content[_menu.selected_index].legend then
      gui.text(_menu_x, _menu.bottom - 12, _menu.content[_menu.selected_index]:legend(), text_disabled_color, text_default_border_color)
    end
  end
end
