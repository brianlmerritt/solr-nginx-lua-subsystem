-- proxy.lua
-- Simple proxy module for Solr requests
-- This will be extended later to add Redis "tee" functionality

local _M = {}

-- Log request details (for debugging)
function _M.log_request()
    local method = ngx.var.request_method
    local uri = ngx.var.request_uri
    local remote_addr = ngx.var.remote_addr
    
    ngx.log(ngx.INFO, "Proxying request: ", method, " ", uri, " from ", remote_addr)
end

-- Placeholder for future tee functionality
function _M.tee_request()
    -- This is where we'll add Redis integration later
    -- For now, just pass through
    return true
end

-- Main proxy handler
function _M.handle_request()
    _M.log_request()
    
    -- Future: Add request teeing here
    local success = _M.tee_request()
    
    if not success then
        ngx.log(ngx.WARN, "Tee functionality failed, but continuing with proxy")
    end
    
    -- Let nginx handle the actual proxying
    return true
end

return _M