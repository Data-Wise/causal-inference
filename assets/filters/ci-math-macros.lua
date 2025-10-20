
-- filters/ci-math-latexify.lua
-- Translate custom macros to standard LaTeX commands that Pandoc/Typst already understand.
-- Adds lowercase variants: \var, \cov, \con, \cor (aliases).

local function braced_unary_to_mathbb(s, cmd, letter, use_brackets)
  local pat = "\\" .. cmd .. "%s*(%b{})"
  return s:gsub(pat, function(braced)
    local inside = braced:sub(2, -2)
    if use_brackets then
      return "\\mathbb{" .. letter .. "}\\left[ " .. inside .. " \\right]"
    else
      return "\\mathbb{" .. letter .. "}\\left( " .. inside .. " \\right)"
    end
  end)
end

local function paren_unary_to_mathbb(s, cmd, letter, use_brackets)
  local pat = "\\" .. cmd .. "%s*(%b())"
  return s:gsub(pat, function(paren)
    local inside = paren:sub(2, -2)
    if use_brackets then
      return "\\mathbb{" .. letter .. "}\\left[ " .. inside .. " \\right]"
    else
      return "\\mathbb{" .. letter .. "}\\left( " .. inside .. " \\right)"
    end
  end)
end

local function braced_unary_to_operator(s, cmd, name)
  local pat = "\\" .. cmd .. "%s*(%b{})"
  return s:gsub(pat, function(braced)
    local inside = braced:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. inside .. " \\right)"
  end)
end

local function paren_unary_to_operator(s, cmd, name)
  local pat = "\\" .. cmd .. "%s*(%b())"
  return s:gsub(pat, function(paren)
    local inside = paren:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. inside .. " \\right)"
  end)
end

local function braced_binary_to_operator(s, cmd, name)
  local pat = "\\" .. cmd .. "%s*(%b{})%s*(%b{})"
  return s:gsub(pat, function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. i1 .. ", " .. i2 .. " \\right)"
  end)
end

local function replace_sets(s)
  s = s:gsub("\\RR", "\\mathbb{R}")
  s = s:gsub("\\NN", "\\mathbb{N}")
  s = s:gsub("\\QQ", "\\mathbb{Q}")
  s = s:gsub("\\ZZ", "\\mathbb{Z}")
  return s
end

local function replace_indicator(s)
  s = s:gsub("\\I%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\mathbf{1}\\{ " .. inside .. " \\}"
  end)
  return s
end

local function replace_independence(s)
  local INDEP = "\\not\\!\\perp\\!\\!\\!\\perp"
  s = s:gsub("\\indep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return i1 .. " " .. INDEP .. " " .. i2
  end)
  -- \indep(X,Y) -> X INDEP Y
  s = s:gsub("\\indep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then
      return a .. " " .. INDEP .. " " .. b
    end
    return INDEP
  end)
  -- bare \indep -> ⫫
  s = s:gsub("\\indep", INDEP)
  return s
end

local function replace_non_independence(s)
  local NOTINDEP = "\\not\\!\\perp\\!\\!\\!\\perp"
  s = s:gsub("\\nindep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return i1 .. " " .. NOTINDEP .. " " .. i2
  end)
  s = s:gsub("\\nindep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then
      return a .. " " .. NOTINDEP .. " " .. b
    end
    return NOTINDEP
  end)
  s = s:gsub("\\notindep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return i1 .. " " .. NOTINDEP .. " " .. i2
  end)
  s = s:gsub("\\notindep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then
      return a .. " " .. NOTINDEP .. " " .. b
    end
    return NOTINDEP
  end)
  s = s:gsub("\\nindep", NOTINDEP)
  s = s:gsub("\\notindep", NOTINDEP)
  return s
end

local function replace_pr(s)
  s = braced_unary_to_operator(s, "Pr", "Pr")
  s = paren_unary_to_operator(s, "Pr", "Pr")
  return s
end

function Math(el)
  local s = el.text

  -- Expectation
  s = braced_unary_to_mathbb(s, "E", "E", true)
  s = paren_unary_to_mathbb(s, "E", "E", true)

  -- Uppercase operator macros (back-compat)
  s = braced_unary_to_operator(s, "Var", "Var")
  s = paren_unary_to_operator(s, "Var", "Var")
  s = braced_binary_to_operator(s, "Cov", "Cov")
  s = braced_binary_to_operator(s, "Cor", "Cor")

  -- Lowercase variants (requested): var, cov, con, cor -> operatorname in lowercase
  s = braced_unary_to_operator(s, "var", "var")
  s = paren_unary_to_operator(s, "var", "var")
  s = braced_binary_to_operator(s, "cov", "cov")
  s = braced_binary_to_operator(s, "con", "cov")  -- treat \con as alias for covariance
  s = braced_binary_to_operator(s, "cor", "cor")

  -- logit, sgn
  s = braced_unary_to_operator(s, "logit", "logit")
  s = braced_unary_to_operator(s, "sgn", "sgn")

  -- Pr
  s = replace_pr(s)

  -- Sets, indicator
  s = replace_sets(s)
  s = replace_indicator(s)

  -- (Non-)independence
  s = replace_non_independence(s)
  s = replace_independence(s)

  return pandoc.Math(el.mathtype, s)
end

-- filters/ci-math-macros.lua
-- Purpose: Translate course-specific LaTeX-style macros into STANDARD LaTeX
-- that Pandoc/Quarto (Typst backend) and MathJax can already understand.
-- This lets you keep typing \E{X}, \var{X}, \indep{X}{Y}, etc.

-- ==========================
-- Utility helpers
-- ==========================
local function braced_unary_to_mathbb(s, cmd, letter, use_brackets)
  -- \cmd{...} -> \mathbb{<letter>}\left[ ... \right] or \left( ... \right)
  local pat = "\\" .. cmd .. "%s*(%b{})"
  return s:gsub(pat, function(b)
    local inside = b:sub(2, -2)
    if use_brackets then
      return "\\mathbb{" .. letter .. "}\\left[ " .. inside .. " \\right]"
    else
      return "\\mathbb{" .. letter .. "}\\left( " .. inside .. " \\right)"
    end
  end)
end

local function paren_unary_to_mathbb(s, cmd, letter, use_brackets)
  -- \cmd( ... ) -> \mathbb{<letter>}\left[ ... \right] or \left( ... \right)
  local pat = "\\" .. cmd .. "%s*(%b())"
  return s:gsub(pat, function(p)
    local inside = p:sub(2, -2)
    if use_brackets then
      return "\\mathbb{" .. letter .. "}\\left[ " .. inside .. " \\right]"
    else
      return "\\mathbb{" .. letter .. "}\\left( " .. inside .. " \\right)"
    end
  end)
end

local function braced_unary_to_operator(s, cmd, name)
  -- \cmd{...} -> \operatorname{<name>}\left( ... \right)
  local pat = "\\" .. cmd .. "%s*(%b{})"
  return s:gsub(pat, function(b)
    local inside = b:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. inside .. " \\right)"
  end)
end

local function paren_unary_to_operator(s, cmd, name)
  -- \cmd( ... ) -> \operatorname{<name>}\left( ... \right)
  local pat = "\\" .. cmd .. "%s*(%b())"
  return s:gsub(pat, function(p)
    local inside = p:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. inside .. " \\right)"
  end)
end

local function braced_binary_to_operator(s, cmd, name)
  -- \cmd{...}{...} -> \operatorname{<name>}\left( ..., ... \right)
  local pat = "\\" .. cmd .. "%s*(%b{})%s*(%b{})"
  return s:gsub(pat, function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return "\\operatorname{" .. name .. "}\\left( " .. i1 .. ", " .. i2 .. " \\right)"
  end)
end

local function braced_unary_to_textop(s, cmd, name)
  -- \cmd{...} -> \mathrm{<name>}\left( ... \right)
  local pat = "\\" .. cmd .. "%s*(%b{})"
  return s:gsub(pat, function(b)
    local inside = b:sub(2, -2)
    return "\\mathrm{" .. name .. "}\\!\\left( " .. inside .. " \\right)"
  end)
end

local function paren_unary_to_textop(s, cmd, name)
  local pat = "\\" .. cmd .. "%s*(%b())"
  return s:gsub(pat, function(p)
    local inside = p:sub(2, -2)
    return "\\mathrm{" .. name .. "}\\!\\left( " .. inside .. " \\right)"
  end)
end

-- ==========================
-- Simple token/structure replacements
-- ==========================
local function replace_sets(s)
  s = s:gsub("\\RR", "\\mathbb{R}")
  s = s:gsub("\\NN", "\\mathbb{N}")
  s = s:gsub("\\QQ", "\\mathbb{Q}")
  s = s:gsub("\\ZZ", "\\mathbb{Z}")
  s = s:gsub("\\PP", "\\mathbb{P}")
  return s
end

local function replace_indicator(s)
  -- \I{A} -> 𝟙{A}; \ind{A} -> 𝕀{A}; \indf{A} -> 𝟙{A}
  s = s:gsub("\\I%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\mathbb{I}\\left\\{ " .. inside .. " \\right\\}"
  end)
  s = s:gsub("\\ind%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\mathbb{I}\\left\\{ " .. inside .. " \\right\\}"
  end)
  s = s:gsub("\\indf%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\mathbf{1}\\left\\{ " .. inside .. " \\right\\}"
  end)
  return s
end

local function replace_abs_norm_ip_vect(s)
  -- \abs{·}, \norm{·}, \ip{·}{·}, \vect{·}
  s = s:gsub("\\abs%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\left\\lvert " .. inside .. " \\right\\rvert"
  end)
  s = s:gsub("\\norm%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\left\\lVert " .. inside .. " \\right\\rVert"
  end)
  s = s:gsub("\\ip%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2)
    local i2 = b2:sub(2, -2)
    return "\\left\\langle " .. i1 .. ",\\, " .. i2 .. " \\right\\rangle"
  end)
  s = s:gsub("\\vect%s*(%b{})", function(b)
    local inside = b:sub(2, -2)
    return "\\mathbf{" .. inside .. "}"
  end)
  return s
end

local function replace_independence(s)
  -- LaTeX independence symbol
  local INDEP = "\\perp\\!\\!\\!\\perp"
  -- Independence: \indep{X}{Y}, \indep(X,Y), bare \indep
  s = s:gsub("\\indep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2); local i2 = b2:sub(2, -2)
    return i1 .. " " .. INDEP .. " " .. i2
  end)
  s = s:gsub("\\indep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then return a .. " " .. INDEP .. " " .. b end
    return INDEP
  end)
  -- Aliases for explicit braced two-arg (MathJax-style): \Indep{X}{Y}
  s = s:gsub("\\Indep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2); local i2 = b2:sub(2, -2)
    return i1 .. " " .. INDEP .. " " .. i2
  end)
  -- Bare symbol
  s = s:gsub("\\indep", INDEP)
  s = s:gsub("\\dsep", INDEP) -- d-separation relation
  return s
end

local function replace_non_independence(s)
  local NOTINDEP = "\\not\\!\\perp\\!\\!\\!\\perp"
  -- \nindep{X}{Y}, \nindep(X,Y)
  s = s:gsub("\\nindep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2); local i2 = b2:sub(2, -2)
    return i1 .. " " .. NOTINDEP .. " " .. i2
  end)
  s = s:gsub("\\nindep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then return a .. " " .. NOTINDEP .. " " .. b end
    return NOTINDEP
  end)
  -- Aliases: \notindep{X}{Y}, \notindep(X,Y)
  s = s:gsub("\\notindep%s*(%b{})%s*(%b{})", function(b1, b2)
    local i1 = b1:sub(2, -2); local i2 = b2:sub(2, -2)
    return i1 .. " " .. NOTINDEP .. " " .. i2
  end)
  s = s:gsub("\\notindep%s*(%b())", function(p)
    local inside = p:sub(2, -2)
    local a, b = inside:match("^%s*(.-)%s*,%s*(.-)%s*$")
    if a and b then return a .. " " .. NOTINDEP .. " " .. b end
    return NOTINDEP
  end)
  -- Bare forms
  s = s:gsub("\\nindep", NOTINDEP)
  s = s:gsub("\\notindep", NOTINDEP)
  return s
end

local function replace_probabilities(s)
  -- \Prob{A}, \pr{A}, and also support \Pr{A}/\Pr(A)
  s = braced_unary_to_mathbb(s, "Prob", "P", false)
  s = paren_unary_to_mathbb(s, "Prob", "P", false)
  s = braced_unary_to_mathbb(s, "pr", "P", false)
  s = paren_unary_to_mathbb(s, "pr", "P", false)
  s = braced_unary_to_operator(s, "Pr", "Pr")
  s = paren_unary_to_operator(s, "Pr", "Pr")
  return s
end

local function replace_expectations(s)
  -- \E{X}, \E(X) -> \mathbb{E}[X]; \Es{θ}{X}
  s = braced_unary_to_mathbb(s, "E", "E", true)
  s = paren_unary_to_mathbb(s, "E", "E", true)
  -- \Es{theta}{X}
  s = s:gsub("\\Es%s*(%b{})%s*(%b{})", function(b1, b2)
    local sub = b1:sub(2, -2); local body = b2:sub(2, -2)
    return "\\mathbb{E}_{" .. sub .. "}\\left[ " .. body .. " \\right]"
  end)
  return s
end

local function replace_operators(s)
  -- Uppercase canonical operators
  s = braced_unary_to_operator(s, "Var", "Var")
  s = paren_unary_to_operator(s, "Var", "Var")
  s = braced_binary_to_operator(s, "Cov", "Cov")
  s = braced_binary_to_operator(s, "Cor", "Cor")
  -- Lowercase convenience forms
  s = braced_unary_to_operator(s, "var", "var")
  s = paren_unary_to_operator(s, "var", "var")
  s = braced_binary_to_operator(s, "cov", "cov")
  s = braced_binary_to_operator(s, "con", "cov") -- alias for covariance
  s = braced_binary_to_operator(s, "cor", "cor")
  -- logit, sgn (both brace and paren)
  s = braced_unary_to_operator(s, "logit", "logit")
  s = paren_unary_to_operator(s, "logit", "logit")
  s = braced_unary_to_operator(s, "sgn", "sgn")
  s = paren_unary_to_operator(s, "sgn", "sgn")
  -- RD/OR simple tokens → operators
  s = s:gsub("\\RD", "\\operatorname{RD}")
  s = s:gsub("\\OR", "\\operatorname{OR}")
  -- argmin/argmax tokens
  s = s:gsub("\\argmin", "\\mathop{\\mathrm{arg\\,min}}\\limits")
  s = s:gsub("\\argmax", "\\mathop{\\mathrm{arg\\,max}}\\limits")
  return s
end

local function replace_do_and_graph(s)
  -- do-operator and d-separation
  s = braced_unary_to_textop(s, "doop", "do")
  s = paren_unary_to_textop(s, "doop", "do")
  -- dsep is same relation symbol as indep
  s = s:gsub("\\dsep", "⫫")
  return s
end

local function replace_potential_outcomes(s)
  -- \Y{a} -> Y^{a}; \Yof{a} -> Y(a)
  s = s:gsub("\\Y%s*(%b{})", function(b)
    local a = b:sub(2, -2)
    return "Y^{" .. a .. "}"
  end)
  s = s:gsub("\\Yof%s*(%b{})", function(b)
    local a = b:sub(2, -2)
    return "Y\\!\\left( " .. a .. " \\right)"
  end)
  -- Shorthands
  s = s:gsub("\\Ya", "Y^a")
  s = s:gsub("\\Yone", "Y^1")
  s = s:gsub("\\Yzero", "Y^0")
  return s
end

local function replace_estimands(s)
  -- ATE/ATT/ATC/CATE tokens
  s = s:gsub("\\ATE", "\\tau_{\\text{ATE}}")
  s = s:gsub("\\ATT", "\\tau_{\\text{ATT}}")
  s = s:gsub("\\ATC", "\\tau_{\\text{ATC}}")
  s = s:gsub("\\CATE", "\\tau_{\\text{CATE}}")
  -- Definitions \DefATE, \DefATT, \DefATC, \DefCATE{·}
  s = s:gsub("\\DefATE", "\\mathbb{E}\\!\\left[ Y(1)-Y(0) \\right]")
  s = s:gsub("\\DefATT", "\\mathbb{E}\\!\\left[ Y(1)-Y(0)\\mid A=1 \\right]")
  s = s:gsub("\\DefATC", "\\mathbb{E}\\!\\left[ Y(1)-Y(0)\\mid A=0 \\right]")
  s = s:gsub("\\DefCATE%s*(%b{})", function(b)
    local cond = b:sub(2, -2)
    return "\\mathbb{E}\\!\\left[ Y(1)-Y(0)\\mid " .. cond .. " \\right]"
  end)
  return s
end

local function replace_identification(s)
  -- g-formula: \gform{a}
  s = s:gsub("\\gform%s*(%b{})", function(b)
    local a = b:sub(2, -2)
    return "\\sum_{l} \\mathbb{E}\\!\\left[ Y \\mid A=" .. a .. ",\\, L=l \\right]\\,\\mathbb{P}(L=l)"
  end)
  -- ipw: \ipw{A=a}{L}
  s = s:gsub("\\ipw%s*(%b{})%s*(%b{})", function(b1, b2)
    local event = b1:sub(2, -2)
    local cond  = b2:sub(2, -2)
    return "\\frac{\\mathbf{1}\\left\\{" .. event .. "\\right\\}}{\\mathbb{P}(" .. event .. "\\mid " .. cond .. ")}"
  end)
  return s
end

-- ==========================
-- Main Pandoc Math handler
-- ==========================
function Math(el)
  local s = el.text

  -- Order matters: handle structured/braced forms first, then tokens
  s = replace_expectations(s)
  s = replace_probabilities(s)
  s = replace_operators(s)
  s = replace_sets(s)
  s = replace_indicator(s)
  s = replace_abs_norm_ip_vect(s)
  s = replace_non_independence(s)
  s = replace_independence(s)
  s = replace_do_and_graph(s)
  s = replace_potential_outcomes(s)
  s = replace_estimands(s)
  s = replace_identification(s)

  return pandoc.Math(el.mathtype, s)
end