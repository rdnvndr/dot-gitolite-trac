# -*- coding: utf-8 -*-
#
# Copyright (C) 2008 Noah Kantrowitz
# Copyright (C) 2012 Ryan J Ollos
# All rights reserved.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution.


from trac.config import ListOption
from trac.core import *
from trac.perm import IPermissionGroupProvider, IPermissionPolicy, \
                      IPermissionRequestor, PermissionSystem
from trac.ticket.model import Ticket
from trac.util.compat import set
from trac.web.chrome import Chrome


class PrivateTicketsPolicy(Component):
    """Central tasks for the PrivateTickets plugin."""
    
    implements(IPermissionRequestor, IPermissionPolicy)
    
    group_providers = ExtensionPoint(IPermissionGroupProvider)
    
    blacklist = ListOption('privatetickets', 'group_blacklist',
                           default='anonymous, authenticated',
                           doc='Groups that do not affect the common'
                               ' membership check.')
    
    ignore_permissions = set([
        'TRAC_ADMIN',
        'TICKET_VIEW',
        'TICKET_REPORTER',
        'TICKET_OWNER',
        'TICKET_CC',
        'TICKET_REPORTER_GROUP',
        'TICKET_OWNER_GROUP',
        'TICKET_CC_GROUP',
    ])
    
    # IPermissionPolicy(Interface)
    def check_permission(self, action, username, resource, perm):
        if username == 'anonymous' or \
           action in self.ignore_permissions or \
           'TRAC_ADMIN' in perm:
            # In these three cases, checking makes no sense
            return None
        
        # Look up the resource parentage for a ticket.
        while resource:
            if resource.realm == 'ticket':
                break
            resource = resource.parent
        if resource and resource.realm == 'ticket' and resource.id:
            return self.check_ticket_access(perm, resource)
        return None
    
    # IPermissionRequestor methods
    def get_permission_actions(self):
        actions = ['TICKET_REPORTER', 'TICKET_OWNER',
                   'TICKET_CC']
        group_actions = ['TICKET_REPORTER_GROUP',
                         'TICKET_OWNER_GROUP',
                         'TICKET_CC_GROUP']
        all_actions = actions + [(a+'_GROUP', [a]) for a in actions]
        return all_actions + [('TICKET_SELF', actions),
                              ('TICKET_GROUP', group_actions)]
    
    # Public methods
    def check_ticket_access(self, perm, res):
        """Return if this req is permitted access to the given ticket ID."""
        try:
            tkt = Ticket(self.env, res.id)
        except TracError:
            return None  # Ticket doesn't exist
        
        had_any = False
        
        if perm.has_permission('TICKET_REPORTER'):
            had_any = True
            if tkt['reporter'] == perm.username:
                return None
        
        if perm.has_permission('TICKET_CC'):
            had_any = True
            cc_list = Chrome(self.env).cc_list(tkt['cc'])
            if perm.username in cc_list:
                return None
        
        if perm.has_permission('TICKET_OWNER'):
            had_any = True
            if perm.username == tkt['owner']:
                return None
        
        if perm.has_permission('TICKET_REPORTER_GROUP'):
            had_any = True
            if self._check_group(perm.username, tkt['reporter']):
                return None
        
        if perm.has_permission('TICKET_OWNER_GROUP'):
            had_any = True
            if self._check_group(perm.username, tkt['owner']):
                return None
        
        if perm.has_permission('TICKET_CC_GROUP'):
            had_any = True
            cc_list = Chrome(self.env).cc_list(tkt['cc'])
            for user in cc_list:
                #self.log.debug('Private: CC check: %s, %s', req.authname, user.strip())
                if self._check_group(perm.username, user):
                    return None
        
        # No permissions assigned, punt
        if not had_any:
            return None
        
        return False

    # Internal methods
    def _check_group(self, user1, user2):
        """Check if user1 and user2 share a common group."""
        user1_groups = self._get_groups(user1)
        user2_groups = self._get_groups(user2)
        both = user1_groups.intersection(user2_groups)
        both -= set(self.blacklist)
        
        #self.log.debug('PrivateTicket: %s&%s = (%s)&(%s) = (%s)', user1, user2, ','.join(user1_groups), ','.join(user2_groups), ','.join(both))
        return bool(both)
    
    def _get_groups(self, user):
        # Get initial subjects
        groups = set([user])
        for provider in self.group_providers:
            for group in provider.get_permission_groups(user):
                groups.add(group)
        
        perms = PermissionSystem(self.env).get_all_permissions()
        repeat = True
        while repeat:
            repeat = False
            for subject, action in perms:
                if subject in groups and not action.isupper() \
                        and action not in groups:
                    groups.add(action)
                    repeat = True 
        
        return groups
