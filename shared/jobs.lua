-- Job lock helper (shared by client + server).
-- A shop with no `jobs` field is open to everyone. Otherwise `jobs` may be:
--   jobs = { 'doctor', 'sheriff' }          -- any grade of these jobs
--   jobs = { doctor = 2, sheriff = 0 }      -- minimum grade per job
--   jobs = { 'doctor', sheriff = 3 }        -- mixed
function PlayerHasShopJob(shop, job)
    local jobs = shop and shop.jobs
    if type(jobs) ~= 'table' or next(jobs) == nil then return true end
    if type(job) ~= 'table' or not job.name then return false end

    local grade = tonumber(job.grade and (job.grade.level or job.grade)) or 0

    for key, value in pairs(jobs) do
        local name, minGrade
        if type(key) == 'number' then
            name, minGrade = value, 0
        else
            name, minGrade = key, tonumber(value) or 0
        end
        if name == job.name and grade >= minGrade then
            return true
        end
    end
    return false
end
