INSERT INTO factJobSkills (
    ONET_SOC_Code,
    Skill_Element,
    Skill_Name,
    Tech_Skill_Key,
    Tech_Skill_Name,
    Job_Title,
    created_at
)
SELECT
    s.ONET_SOC_Code,
    s.Element_ID,
    s.Skill,
    t.Commodity_Code,
    t.Commodity_Title,
    j.Title,
    CURRENT_TIMESTAMP
FROM
    dimSkills s
LEFT JOIN
    dimJobInfo j ON s.ONET_SOC_Code = j.ONET_SOC_Code
LEFT JOIN
    dimTechSkills t ON j.ONET_SOC_Code = t.ONET_SOC_Code
