/**
 * Copyright 2014 Red Hat, Inc.
 *
 * This software is licensed to you under the GNU General Public
 * License as published by the Free Software Foundation; either version
 * 2 of the License (GPLv2) or (at your option) any later version.
 * There is NO WARRANTY for this software, express or implied,
 * including the implied warranties of MERCHANTABILITY,
 * NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
 * have received a copy of GPLv2 along with this software; if not, see
 * http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
 */

describe('Filter: filterType', function() {
    var filterTypeFilter;

    beforeEach(module('Bastion.content-views'));

    beforeEach(module(function ($provide) {
        $provide.value('translate', function (string) { return string; });
    }));

    beforeEach(inject(function($filter) {
        filterTypeFilter = $filter('filterType');
    }));

    it("provides a filter shell around transforming type for a filter", function() {
        expect(filterTypeFilter(true)).toBe('Include');
    });

});
