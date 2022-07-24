#include <hxcpp.h>
#include "Steamworks.hpp"

bool steamworks::init()
{
    return SteamAPI_Init();
}

void steamworks::pump()
{
    SteamAPI_RunCallbacks();
}

void steamworks::shutdown()
{
    SteamAPI_Shutdown();
}

void steamworks::MncServerList::strncpy_safe(char* pDest, char const* pSrc, size_t maxLen)
{
    auto nCount     = maxLen;
    auto pstrDest   = pDest;
    auto pstrSource = pSrc;

    while (0 < nCount && 0 != (*pstrDest++ = *pstrSource++))
    {
        nCount--;
    }

    if (maxLen > 0)
    {
        pstrDest[-1] = 0;
    }
}

steamworks::MncServerList::MncServerList(Dynamic _responseCallback, Dynamic _responseFailedCallback, Dynamic _refreshCallback)
    : responseCallback(_responseCallback)
    , responseFailedCallback(_responseFailedCallback)
    , refreshCallback(_refreshCallback)
    , request(queryInternetServers())
{
    hx::GCAddRoot(const_cast<hx::Object**>(&responseCallback.mPtr));
    hx::GCAddRoot(const_cast<hx::Object**>(&responseFailedCallback.mPtr));
    hx::GCAddRoot(const_cast<hx::Object**>(&refreshCallback.mPtr));
}

steamworks::MncServerList::~MncServerList()
{
    hx::GCRemoveRoot(const_cast<hx::Object**>(&responseCallback.mPtr));
    hx::GCRemoveRoot(const_cast<hx::Object**>(&responseFailedCallback.mPtr));
    hx::GCRemoveRoot(const_cast<hx::Object**>(&refreshCallback.mPtr));

    SteamMatchmakingServers()->CancelQuery(request);
    SteamMatchmakingServers()->ReleaseRequest(request);
}

HServerListRequest steamworks::MncServerList::queryInternetServers()
{
    MatchMakingKeyValuePair_t filters[1];
    MatchMakingKeyValuePair_t* filter = filters;
    strncpy_safe( filters[0].m_szKey, "dedicated", sizeof(filters[0].m_szKey) );
	strncpy_safe( filters[0].m_szValue, "1", sizeof(filters[0].m_szValue) );

    return SteamMatchmakingServers()->RequestInternetServerList(63200, &filter, 1, this);
}

void steamworks::MncServerList::Refresh()
{
    SteamMatchmakingServers()->ReleaseRequest(request);

    request = queryInternetServers();
}

void steamworks::MncServerList::ServerResponded(HServerListRequest _request, int _index)
{
    auto details = SteamMatchmakingServers()->GetServerDetails(request, _index);

    responseCallback(
        _index,
        details->m_nPlayers,
        details->m_nMaxPlayers,
        String::create(details->m_szGameDescription),
        String::create(details->m_szGameTags));
}

void steamworks::MncServerList::ServerFailedToRespond(HServerListRequest _request, int _index)
{
    responseFailedCallback(_index);
}

void steamworks::MncServerList::RefreshComplete(HServerListRequest _request, EMatchMakingServerResponse _response)
{
    refreshCallback(_response);
}

steamworks::MncServerList* steamworks::MncServerList::Create(Dynamic _responseCallback, Dynamic _responseFailedCallback, Dynamic _refreshCallback)
{
    return new MncServerList(_responseCallback, _responseFailedCallback, _refreshCallback);
}