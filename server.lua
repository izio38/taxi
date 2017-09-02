--[[
##################
#    Oskarr      #
#    MysticRP    #
#   server.lua   #
#      2017      #
##################
--]]

local taxijob = '5' -- Change by your job id for taxi
local boss = 'steam:110000101001010' -- Boss 1 
local boss2 = 'steam:110000101001010' -- Boss 2 
local tauxblanchiment = 0.85 -- 0.85 = 100 000 money -> 85 000 dirty money

RegisterServerEvent('taxi:factureGranted')
AddEventHandler('taxi:factureGranted', function(target, amount)
	local source = source
	TriggerClientEvent('taxi:payFacture', target, amount, source)
	TriggerClientEvent("taxi:notify", source, "CHAR_TAXI", 1, "Facture Taxi", false, "Facture de ~g~"..amount.."$~s~ envoyée à "..GetPlayerName(target))
end)

RegisterServerEvent('taxi:factureETA')
AddEventHandler('taxi:factureETA', function(officer, code)
	local source = source
	if(code==1) then
		TriggerClientEvent("taxi:notify", officer, "CHAR_TAXI", 1, "Facture Taxi", false, GetPlayerName(source).."~b~ à déjà une demande de facture en cours !")
	elseif(code==2) then
		TriggerClientEvent("taxi:notify", officer, "CHAR_TAXI", 1, "Facture Taxi", false, GetPlayerName(source).."~y~ n'a pas répondu à la demande de facture !")
	elseif(code==3) then
		TriggerClientEvent("taxi:notify", officer, "CHAR_TAXI", 1, "Facture Taxi", false, GetPlayerName(source).."~r~ à refuser de payer la facture !")
	elseif(code==0) then
		TriggerClientEvent("taxi:notify", officer, "CHAR_TAXI", 1, "Facture Taxi", false, GetPlayerName(source).."~g~ à payer la facture !")
	end
end)

RegisterServerEvent('taxi:sv_setService')
AddEventHandler('taxi:sv_setService',
  function(service)
    local source = source
    TriggerEvent('es:getPlayerFromId', source,
      function(user)
	MySQL.Sync.execute("UPDATE users SET enService = @service WHERE identifier = @identifier",
	{
		["@service"] = 	service,
		["@identifier"] = user.get('identifier')
	})
      end
    )
  end
)

RegisterServerEvent('taxi:sv_getJobId')
AddEventHandler('taxi:sv_getJobId',
  function()
    local source = source
    TriggerClientEvent('taxi:cl_setJobId', source, GetJobId(source))
  end
)


function idJob(player)
  local result = MySQL.Sync.fetchAll("SELECT * FROM users LEFT JOIN jobs ON jobs.job_id = users.job WHERE users.identifier = @identifier",
  {
	["@identifier"] = player
  })
  return tostring(result[1].job_id)
end

function GetDirtySolde()
  local result = MySQL.Sync.fetchAll("SELECT dirtysolde FROM coffretaxi WHERE id = '1' ")
  return tostring(result[1].dirtysolde)
end

function updateCoffreDirty(player, prixavant,prixtotal,prixajoute)
  MySQL.Sync.execute("UPDATE coffretaxi SET `dirtysolde`=@prixtotal , identifier = @identifier , lasttransfert = @prixajoute WHERE dirtysolde = @prixavant AND id = '1'", 
  {
	["@prixtotal"] = prixtotal,
	["@identifier"] = player,
	["@prixajoute"] = prixajoute,
	["@prixavant"] = prixavant
  })
end


function ajoutFactureToCoffre(amount)
  MySQL.Sync.fetchAll("UPDATE coffretaxi SET `solde`=@amount WHERE id = '1' ",
  {
	["@amount"] = amount
  })
end



RegisterServerEvent('coffretaxi:facturecoffre')
AddEventHandler('coffretaxi:facturecoffre', function(amount)
  local solde = GetSolde()
  local amount = amount
  local total = amount + solde
  ajoutFactureToCoffre(total)
end)

function updateCoffre(player, prixavant,prixtotal,prixajoute)
  MySQL.Sync.execute("UPDATE coffretaxi SET `solde`=@prixtotal , identifier = @identifier , lasttransfert = @prixajoute WHERE solde = @prixavant AND id = '1' ", 
  {
	["@prixtotal"] = prixtotal,
	["@identifier"] = player,
	["@prixajoute"] = prixajoute,
	["@prixavant"] = prixavant
  })
end

function GetSolde()
  local result = MySQL.Sync.fetchAll("SELECT solde FROM coffretaxi WHERE id ='1' ")
  return tostring(result[1].solde)
end

RegisterServerEvent('coffretaxi:getsolde')
AddEventHandler('coffretaxi:getsolde',function()
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
  local player = user.get('identifier')
   local idjob = idJob(player) 
  if(idjob == taxijob and player == boss or player == boss2) then
  local data = GetSolde()
  print(data)
  TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Solde restant : ~b~"..data.."$")
  else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
  end
end)
end)


RegisterServerEvent('coffretaxi:ajoutsolde')
AddEventHandler('coffretaxi:ajoutsolde',function(ajout)
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
    local player = user.get('identifier')
    local idjob = idJob(player) 

    if(idjob == taxijob and player == boss or player == boss2)then
      local prixavant = GetSolde()
      local prixajoute = ajout
      local prixtotal = prixavant+prixajoute    
      print(player)
      print(prixavant)
      print(prixajoute)
      print(prixtotal)
      if(tonumber(prixajoute) <= tonumber(user.get('money')) and tonumber(prixajoute) >= 0) then    
        user.removeMoney((prixajoute))
        updateCoffre(player,prixavant,prixtotal,prixajoute)
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Dépôt : +~g~"..prixajoute.."$")
      else
         TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "ATTENTION", false, "~r~Vous n'avez pas assez d'argent !")
      end
     else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
    end
end)
end)


RegisterServerEvent('coffretaxi:retirersolde')
AddEventHandler('coffretaxi:retirersolde',function(ajout)
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
    local player = user.get('identifier')
    local idjob = idJob(player)
    if(idjob == taxijob and player == boss or player == boss2)then
      local prixavant = GetSolde()
      local prixenleve = ajout
      local prixtotal = prixavant-prixenleve    
      print(player)
      print(prixavant)
      print(prixenleve)
      print(prixtotal)
    
      if(tonumber(prixenleve) >= 0 and tonumber(prixtotal) >= -1) then    
	    updateCoffre(player,prixavant,prixtotal,prixenleve)
        user.addMoney(prixenleve)
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Retrait: -~r~"..prixenleve.." $")   
      else
               TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Coffre vide ou montant invalide !")  
      end
     else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
    end
end)
end)

RegisterServerEvent('coffretaxi:getdirtysolde')
AddEventHandler('coffretaxi:getdirtysolde',function()
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
  local player = user.get('identifier')
   local idjob = idJob(player) 
  if(idjob == taxijob and player == boss or player == boss2)then
  local data = GetDirtySolde()
  print(data)
  TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Solde restant : ~b~"..data.."$")
  else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
  end
end)
end)

RegisterServerEvent('coffretaxi:ajoutdirtysolde')
AddEventHandler('coffretaxi:ajoutdirtysolde',function(ajout)
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
    local player = user.get('identifier')
    local idjob = idJob(player) 
	local dcash = tonumber(user.getDirty_Money())
    if(idjob == taxijob and player == boss or player == boss2)then
      local prixavant = GetDirtySolde()
      local prixajoute = ajout
      local prixtotal = prixavant+prixajoute    
      print(player)
      print(prixavant)
      print(prixajoute)
      print(prixtotal)
      if(tonumber(prixajoute) <= tonumber(dcash) and tonumber(prixajoute) >= 0) then    
        user.removeDirty_Money(prixajoute)
        updateCoffreDirty(player,prixavant,prixtotal,prixajoute)
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Dépôt : +~g~"..prixajoute.."$")
      else
         TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Vous n'avez pas assez d'argent !")
      end
      else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
    end
end)
end)


RegisterServerEvent('coffretaxi:retirerdirtysolde')
AddEventHandler('coffretaxi:retirerdirtysolde',function(ajout)
local source = source
TriggerEvent('es:getPlayerFromId', source, function(user)
    local player = user.get('identifier')
    local idjob = idJob(player)
    local dcash = tonumber(user.getDirty_Money())
    if(idjob == taxijob and player == boss or player == boss2)then
      local prixavant = GetDirtySolde()
      local prixenleve = ajout
      local prixtotal = prixavant-prixenleve    
      print(player)
      print(prixavant)
      print(prixenleve)
      print(prixtotal)
    
      if(tonumber(prixenleve) >= 0 and tonumber(prixtotal) >= -1) then    
	     updateCoffreDirty(player,prixavant,prixtotal,prixenleve)
        user.addDirty_Money(prixenleve)
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "Retrait: -~r~"..prixenleve.." $")   
	  else
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Coffre vide ou montant invalide !") 
      end
      else
   TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Coffre Entreprise", false, "~r~Tu n'est pas le patron !")
    end
end)
end)

RegisterServerEvent("taxi:BlanchirCash")
AddEventHandler("taxi:BlanchirCash", function(amount)
	local source = source
	TriggerEvent('es:getPlayerFromId', source, function(user)
	 local player = user.get('identifie')r
     local idjob = idJob(player)

       if(idjob == taxijob and player == boss or player == boss2)then
		local cash = tonumber(user.getMoney())
		local dcash = tonumber(user.getDirty_Money())
	    local ablanchir = amount
		
		if (dcash <= 0 or ablanchir <= 0) then
			 TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Blanchisserie", false, "~y~Tu n'a pas d'argent à blanchir")
		else
		local washedcash = ablanchir * tauxblanchiment
		local total = cash + washedcash
		local totald = dcash - ablanchir
		user.setMoney(total)
		user.setDirty_Money(totald)
	    TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Blanchisserie", false, "Vous avez blanchi ~r~".. tonumber(ablanchir) .."$~s~ d'argent sale.~s~ Vous avez maintenant ~g~".. tonumber(total) .."$")
	    end
    	else
        TriggerClientEvent("es_freeroam:notify", source, "CHAR_TAXI", 1, "Blanchisserie", false, "~r~Tu n'est pas le patron !")
        end
	end)
end)


RegisterServerEvent("taxi:cautionOn")
AddEventHandler("taxi:cautionOn", function(cautionprice)
	local source = source
	TriggerEvent('es:getPlayerFromId', source, function(user)
	user.removeMoney(cautionprice)
	end)	
	end)
	
	RegisterServerEvent("taxi:cautionOff")
AddEventHandler("taxi:cautionOff", function(cautionprice)
	local source = source
	TriggerEvent('es:getPlayerFromId', source, function(user)
	user.addMoney(cautionprice)
	end)	
	end)


--AddEventHandler('playerDropped', function()
 -- TriggerEvent('es:getPlayerFromId', source,
  --  function(user)
 --     local executed_query = MySQL:executeQuery("UPDATE users SET enService = 0 WHERE users.identifier = '@identifier'", {['@identifier'] = user.identifier})
 --   end
 -- )
--end)


function GetJobId(source)
  local jobId = -1

  TriggerEvent('es:getPlayerFromId', source,
    function(user)
      local result = MySQL.Sync.fetchAll("SELECT identifier, job_id, job_name FROM users LEFT JOIN jobs ON jobs.job_id = users.job WHERE users.identifier = @identifier AND job_id IS NOT NULL", 
      {
	["@"] = user.get('identifier')
      })
      if (result[1] ~= nil) then
        jobId = result[1].job_id
      end
    end
  )

  return jobId
end
