#!/usr/bin/python
#
# Copyright (c) 2020  haiyuazhang <haiyzhan@micosoft.com>
#
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
from types import LambdaType
__metaclass__ = type


DOCUMENTATION = '''
---
module: azure_rm_managedidentity
version_added: '1.2.0'
short_description: Manage Azure Managed Identities
description:
    - Create, update and delete identities
options:
'''
EXAMPLES = '''
'''
RETURN = '''
'''

import time
import json
import random
from ansible_collections.azure.azcollection.plugins.module_utils.azure_rm_common_ext import AzureRMModuleBaseExt
from ansible_collections.azure.azcollection.plugins.module_utils.azure_rm_common_rest import GenericRestClient

class Actions:
    NoAction, Create, Update, Delete = range(4)


class AzureRMManagedIdentity(AzureRMModuleBaseExt):
    def __init__(self):
        self.module_arg_spec = dict(
            resource_group=dict(
                type='str',
                required=True
            ),
            name=dict(
                type='str',
                required=True
            ),
            location=dict(
                type='str',
            ),
        )
        self.resource_group = None
        self.name = None

        self.results = dict(changed=False)
        self.mgmt_client = None
        self.state = None
        self.url = None
        self.status_code = [200, 201, 202]
        self.to_do = Actions.NoAction

        self.body = {}
        self.body['properties'] = {}
        self.query_parameters = {}
        self.header_parameters = {}

        self.api_version = '2023-11-22'
        self.rp_mode = 'production'
        self.header_parameters['Content-Type'] = 'application/json; charset=utf-8'

        super(AzureRMOpenShiftManagedClusters, self).__init__(derived_arg_spec=self.module_arg_spec,
                                                              supports_check_mode=True,
                                                              supports_tags=True)

    def exec_module(self, **kwargs):
        for key in list(self.module_arg_spec.keys()) + ['tags']:
            if hasattr(self, key):
                setattr(self, key, kwargs[key])

        response = None

        self.mgmt_client = self.get_mgmt_svc_client(GenericRestClient,
                                                    base_url=self._cloud_environment.endpoints.resource_manager)
        self.query_parameters['api-version'] = self.api_version
        self.results["api_version"] = self.api_version
        if self.rp_mode != "production":
            self.results["rp_mode"] = self.rp_mode

        self.url = "/".join([
            'subscriptions',
            self.subscription_id,
            '/resourceGroups',
            self.resource_group,
            'providers',
            'Microsoft.RedHatOpenShift',
            'openShiftClusters',
            self.name
        ])
        self.url = self.url.replace('{{ subscription_id }}', self.subscription_id)
        self.url = self.url.replace('{{ resource_group }}', self.resource_group)
        self.url = self.url.replace('{{ open_shift_managed_cluster_name }}', self.name)

        old_response = self.get_resource()
