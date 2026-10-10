local D=require('Dora');local S={}
local function open()return D.DB:existDB('lsd')and D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0DisarmComparisons(id INTEGER PRIMARY KEY AUTOINCREMENT,identity TEXT NOT NULL UNIQUE,payload TEXT NOT NULL)')>=0 end
function S.saveAsync(record)
 local review,why=require('Training.DisarmCompare').review(record);if not review then return nil,why end
 local identity=record.runs[1].trace.resources.attempt
 local payload=D.json.encode(record,false,true);if #payload>40*1024*1024 then return nil,'COMPARISON_TOO_LARGE'end
 if not open()then return nil,'WRITE_FAILED'end
 local rows=D.DB:query('SELECT id,payload FROM lsd.Game0DisarmComparisons WHERE identity=?',{identity})
 if not rows then return nil,'READ_FAILED'end
 if rows[1]then if require('Training.FlowerIdentity').equal(D.json.decode(rows[1][2],32),D.json.decode(payload,32))then return rows[1][1]end;return nil,'COMPARISON_CONFLICT'end
 if not D.DB:transactionAsync({{'INSERT INTO lsd.Game0DisarmComparisons(identity,payload) VALUES(?,?)',{{identity,payload}}}})then return nil,'WRITE_FAILED'end
 rows=D.DB:query('SELECT id FROM lsd.Game0DisarmComparisons WHERE identity=?',{identity});if not rows or not rows[1]then return nil,'READ_FAILED'end;return rows[1][1]
end
local function decode(rows)
 if not rows then return nil,'READ_FAILED'end;if not rows[1]then return nil,'NOT_RECORDED'end
 if #rows[1][2]>40*1024*1024 then return nil,'COMPARISON_TOO_LARGE'end
 local ok,record=pcall(D.json.decode,rows[1][2],32);if not ok then return nil,'INVALID_RECORD'end
 local review,why=require('Training.DisarmCompare').review(record);if not review then return nil,why end
 return {id=rows[1][1],record=record,review=review}
end
function S.list()
 if not open()then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT id FROM lsd.Game0DisarmComparisons ORDER BY id DESC LIMIT 20');if not rows then return nil,'READ_FAILED'end
 local ids={};for _,row in ipairs(rows)do ids[#ids+1]=row[1]end;return ids
end
function S.load(id)
 if type(id)~='number'or id<1 or id%1~=0 then return nil,'INVALID_ID'end
 if not open()then return nil,'READ_FAILED'end
 return decode(D.DB:query('SELECT id,payload FROM lsd.Game0DisarmComparisons WHERE id=?',{id}))
end
function S.loadLatest()
 if not open()then return nil,'READ_FAILED'end
 return decode(D.DB:query('SELECT id,payload FROM lsd.Game0DisarmComparisons ORDER BY id DESC LIMIT 1'))
end
return S
