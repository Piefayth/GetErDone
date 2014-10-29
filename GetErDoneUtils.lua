function GetErDone:nextReset(frequency, region)
  currentDate = os.date("!*t")
  --currentDate = {["wday"] = 4, ["day"] = 1, ["month"] = 11, ["year"] = 2014, ["hour"] = 12}
  monthdays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if currentDate["year"] % 4 == 0 then monthdays[2] = 29 end

  resetDate = {["year"] = "", ["day"] = "", ["month"] = "", ["hour"] = ""}

  regionDayMap = {["US"] = {["day"] = 3, ["hour"] = 11},
  				  ["EU"] = {["day"] = 4, ["hour"] = 2},
  				  ["AU"] = {["day"] = 2, ["hour"] = 17}}

  daysRemaining = 0
  regionalResetHour = regionDayMap[region].hour
  if frequency == "weekly" then
  	regionalResetDay = regionDayMap[region].day
    if currentDate["wday"] > regionalResetDay then --If it's after the resetDate day
      daysRemaining = regionalResetDay + 7 - currentDate["wday"]
    elseif currentDate["wday"] < regionalResetDay then
      daysRemaining = regionalResetDay - currentDate["wday"] --If it's Sunday or Monday
    elseif currentDate["wday"] == regionalResetDay then -- If it's Tuesday
      if currentDate["hour"] < regionalResetHour then daysRemaining = 0 end
      if currentDate["hour"] >= regionalResetHour then daysRemaining = 7 end
    end
    resetDate = addDays(resetDate, currentDate, daysRemaining)
  elseif frequency == "daily" then
    resetDate = addDays(resetDate, currentDate, 1)
  elseif frequency == "monthly" then
    daysRemaining = monthdays[currentDate["month"]] - currentDate["day"] + 1
    resetDate = addDays(resetDate, currentDate, daysRemaining)
  else
    return nil
  end
  resetDate["hour"] = regionalResetHour
  return os.time(resetDate)
end

function GetErDone:addDays(resetDate, currentDate, days)
  monthdays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  DECEMBER = 12
  JANUARY = 1
  -- leap years
  if currentDate["year"] % 4 == 0 then monthdays[2] = 29 end

  -- if we need to go to next month
  if days + currentDate["day"] > monthdays[currentDate["month"]] then
    if currentDate["month"] == DECEMBER then 
      resetDate["day"] =  (currentDate["day"] + days) - monthdays[currentDate["month"]]
      resetDate["month"] = JANUARY
      resetDate["year"] = currentDate["year"] + 1
    else
      resetDate["day"] =  (currentDate["day"] + days) - monthdays[currentDate["month"]]
      resetDate["month"] = currentDate["month"] + 1
      resetDate["year"] = currentDate["year"]
    end
  else
    resetDate["day"] = currentDate["day"] + days
    resetDate["month"] = currentDate["month"]
    resetDate["year"] = currentDate["year"]
  end
  return resetDate
end

