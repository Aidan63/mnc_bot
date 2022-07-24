#pragma once

#ifndef HXCPP_H
#include <hxcpp.h>
#endif

#include <steam_api.h>

namespace steamworks
{
    bool init();

    void pump();

    void shutdown();

    class MncServerList : public ISteamMatchmakingServerListResponse
    {
    private:
        Dynamic responseCallback;
        Dynamic responseFailedCallback;
        Dynamic refreshCallback;
        HServerListRequest request;

        HServerListRequest queryInternetServers();

        static void strncpy_safe(char*, char const*, size_t);

    public:
        MncServerList(Dynamic, Dynamic, Dynamic);
        ~MncServerList();

        void Refresh();
        void ServerResponded(HServerListRequest, int);
        void ServerFailedToRespond(HServerListRequest, int);
        void RefreshComplete(HServerListRequest, EMatchMakingServerResponse);

        static MncServerList* Create(Dynamic, Dynamic, Dynamic);
    };
}