-- The catalog is separate from journey data; a failed selection never resets a save.
local D=require('Dora');local Selection={}
local function withCatalog(directory,create,action)
 local path=D.Path(directory,'lsd-save-catalog.db')
 if not create and not D.Content:exist(path)then return nil end
 if D.DB:existDB('save_catalog')then return nil,'CATALOG_BUSY'end
 local ok,result=pcall(function()return D.DB:exec("ATTACH DATABASE '"..path:gsub("'","''").."' AS save_catalog")end)
 if not ok or result<0 then return nil,'CATALOG_UNREADABLE'end
 local ran,value,why=pcall(function()
  local rows=D.DB:query('PRAGMA save_catalog.quick_check')
  if not rows or not rows[1]or rows[1][1]~='ok'then return nil,'CATALOG_UNREADABLE'end
  if create and D.DB:exec('CREATE TABLE IF NOT EXISTS save_catalog.Selection(id INTEGER PRIMARY KEY CHECK(id=1),name TEXT NOT NULL)')<0 then return nil,'SELECTION_WRITE_FAILED'end
  return action()
 end)
 D.DB:exec('DETACH DATABASE save_catalog')
 if not ran then return nil,'CATALOG_UNREADABLE'end
 return value,why
end
function Selection.read(directory)
 return withCatalog(directory,false,function()
  local rows=D.DB:query('SELECT name FROM save_catalog.Selection WHERE id=1')
  if not rows then return nil,'CATALOG_UNREADABLE'end
  return rows[1]and rows[1][1]
 end)
end
function Selection.write(directory,name)
 return withCatalog(directory,true,function()
  local ok=D.DB:transaction({{'INSERT OR REPLACE INTO save_catalog.Selection(id,name) VALUES(1,?)',{{name}}}})
  return ok,ok and nil or 'SELECTION_WRITE_FAILED'
 end)
end
return Selection
