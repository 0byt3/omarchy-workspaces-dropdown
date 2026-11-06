.pragma library

function pageEntries(values, pageIndex, pageSize) {
  var lastPage = Math.max(0, Math.ceil(values.length / pageSize) - 1)
  var start = Math.max(0, Math.min(pageIndex, lastPage)) * pageSize
  return values.slice(start, start + pageSize)
}

function numbered(workspace) {
  return workspace && Number(workspace.id) > 0
}

function label(workspace) {
  if (!workspace) return ""
  return numbered(workspace) ? String(workspace.id) : String(workspace.name || "")
}

// Natural, case-insensitive alphanumeric order: 2 before 10, Desk2 before Desk10.
function compareLabels(left, right) {
  var a = left.toLowerCase().match(/\d+|\D+/g) || []
  var b = right.toLowerCase().match(/\d+|\D+/g) || []
  for (var i = 0; i < Math.min(a.length, b.length); i++) {
    var x = a[i], y = b[i]
    if (/^\d+$/.test(x) && /^\d+$/.test(y)) {
      x = x.replace(/^0+/, "") || "0"
      y = y.replace(/^0+/, "") || "0"
      if (x.length !== y.length) return x.length - y.length
    }
    if (x !== y) return x < y ? -1 : 1
  }
  if (a.length !== b.length) return a.length - b.length
  return left === right ? 0 : (left < right ? -1 : 1)
}

function sortedWorkspaces(values) {
  var result = []
  for (var i = 0; i < values.length; i++) {
    var workspace = values[i]
    if (workspace && label(workspace) !== "" && String(workspace.name || "").indexOf("special:") !== 0)
      result.push(workspace)
  }
  result.sort(function(a, b) {
    var order = compareLabels(label(a), label(b))
    return order !== 0 ? order : Number(a.id) - Number(b.id)
  })
  return result
}

function selector(workspace) {
  return numbered(workspace) ? String(workspace.id) : "name:" + workspace.name
}

// Escape Lua strings separately from shell quoting (handled by Util.shellQuote).
function luaQuote(value) {
  return '"' + String(value).replace(/[\x00-\x1f\x7f\\"]/g, function(character) {
    if (character === "\\") return "\\\\"
    if (character === '"') return '\\"'
    var code = String(character.charCodeAt(0))
    return "\\" + ("000" + code).slice(-3)
  }) + '"'
}

function focusExpression(workspace) {
  return "hl.dsp.focus({ workspace = " + luaQuote(selector(workspace)) + " })"
}
