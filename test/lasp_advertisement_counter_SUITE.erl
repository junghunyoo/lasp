%% -------------------------------------------------------------------
%%
%% Copyright (c) 2016 Christopher Meiklejohn.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
%%

-module(lasp_advertisement_counter_SUITE).
-author("Christopher Meiklejohn <christopher.meiklejohn@gmail.com>").

%% common_test callbacks
-export([%% suite/0,
         init_per_suite/1,
         end_per_suite/1,
         init_per_testcase/2,
         end_per_testcase/2,
         all/0]).

%% tests
-compile([export_all]).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("kernel/include/inet.hrl").

%% ===================================================================
%% common_test callbacks
%% ===================================================================

init_per_suite(_Config) ->
    lager:start(),
    %% this might help, might not...
    os:cmd(os:find_executable("epmd")++" -daemon"),
    {ok, Hostname} = inet:gethostname(),
    case net_kernel:start([list_to_atom("runner@"++Hostname), shortnames]) of
        {ok, _} -> ok;
        {error, {already_started, _}} -> ok
    end,
    lager:info("node name ~p", [node()]),
    _Config.

end_per_suite(_Config) ->
    application:stop(lager),
    _Config.

init_per_testcase(Case, Config) ->
    Nodes = [First|Rest] = lasp_test_utils:pmap(fun(N) -> lasp_test_utils:start_node(N, Config, Case) end, [jaguar, shadow, thorn, pyros]),
    ct:pal("Nodes: ~p", [Nodes]),

    %% Attempt to join all nodes in the cluster.
    lists:foreach(fun(N) ->
                        ct:pal("Joining node: ~p to ~p", [N, First]),
                        ok = rpc:call(First, lasp_peer_service, join, [N])
                  end, Rest),

    %% Wait until convergence.
    lasp_test_utils:wait_until_joined(Nodes, Nodes),
    ct:pal("Cluster converged."),

    {ok, _} = ct_cover:add_nodes(Nodes),
    [{nodes, Nodes}|Config].

end_per_testcase(_, _Config) ->
    lasp_test_utils:pmap(fun(Node) -> ct_slave:stop(Node) end, [jaguar, shadow, thorn, pyros]),
    ok.

all() ->
    [
        advertisement_counter_orset_gcounter_10000_100_10_test,
        advertisement_counter_orset_gcounter_10000_500_10_test,
        advertisement_counter_orset_gcounter_10000_1000_10_test
    ].

%% ===================================================================
%% tests
%% ===================================================================

advertisement_counter_orset_gcounter_10000_100_10_test(Config) ->
    [Node1 | _Nodes] = proplists:get_value(nodes, Config),
    {ok, _} = rpc:call(Node1, lasp_advertisement_counter, run,
                       [[lasp_orset, lasp_gcounter, 10000, 100, 10]]),
    ok.

advertisement_counter_orset_gcounter_10000_500_10_test(Config) ->
    [Node1 | _Nodes] = proplists:get_value(nodes, Config),
    {ok, _} = rpc:call(Node1, lasp_advertisement_counter, run,
                       [[lasp_orset, lasp_gcounter, 10000, 500, 10]]),
    ok.

advertisement_counter_orset_gcounter_10000_1000_10_test(Config) ->
    [Node1 | _Nodes] = proplists:get_value(nodes, Config),
    {ok, _} = rpc:call(Node1, lasp_advertisement_counter, run,
                       [[lasp_orset, lasp_gcounter, 10000, 1000, 10]]),
    ok.
