/**
 *
 */

//Assuming BK_PLATFORM defined already.[all|ios|android|web]

// BK library ---
var $BK$; // global reference for BK library

(function() {
    'use strict';

    function define_library() { // --- BK library scope

        /* private */
        var BK = {}; // private
        BK.version = "v1.0.2";
        var BK_PLATFORM = void 0;

        var rules = [];

        var aggregatesModifiedCallback = void 0;
        var aggregatesMap = [];
        var pushRepeatCounts = {};

        /**
        BKDate util
        */
        var bkDate = {
            utcNow: function() {
                var today = new Date();
                return Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate(), today.getUTCHours(), today.getUTCMinutes(), today.getUTCSeconds(), today.getUTCMilliseconds());
            },
            utcToday: function() {
                var today = new Date();
                return Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getDate(), 0, 0, 0, 0);
            },
            utcCurrentMonth: function() {
                var today = new Date();
                return Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), 1, 0, 0, 0, 0);
            },
            utcCurrentYear: function() {
                var today = new Date();
                return Date.UTC(today.getUTCFullYear(), 0, 1, 0, 0, 0, 0);
            },
            getDay: function(t) {
                var today = new Date(t);
                return Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getDate(), 0, 0, 0, 0);
            }

        };

        BK.log = function(msg) {/* override this function for logs */
        }; // public reference

        /**
         * evaluates given filter, and returns boolean
         */
        function evaluate(filterRef, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess) {
            if (rule) {
                BK.log("evaluating...:" + filterRef.code + " in RuleId:" + rule.id);
            }

            var r = false;

            if (filterRef.type === "group") {
                r = evaluateGroupFilter(filterRef, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess);
            } else if (filterRef.type === "single") {
                r = evaluateSingleFilter(filterRef, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess);
            }
            if (rule) {
                BK.log("evaluated:" + filterRef.code + ":" + r + " in RuleId:" + rule.id);
            }

            return r;
        }

        function getEventTypeForString(eventType) {
            if (eventType === "CustomEvents") {
                return 8;
            } else if (eventType === "Instasense") {
                return 10;
            } else if (eventType === "Location") {
                return 4;
            }
        }

        var keywords = [];

        function evaluateAggreate(upshotEvent, dummyAggregates/* out_variable */) {
            keywords = [];
            var rulesMap = {}; // [ruleId->true]

            if (aggregatesMap.length === 0) {
                return  rulesMap;
            }

            for (var i = 0, ilen = aggregatesMap.length; i < ilen; i++) {

                var aggregate = aggregatesMap[i];

                if (!(aggregate.platform === BK_PLATFORM || aggregate.platform === 'all')) {
                    // aggregate's platform is not either current platform or 'all'
                    // we can skip this aggregate update.
                    continue;
                }
                // Check this condition before prodding
                // if ((aggregate.sub_event === upshotEvent.subtype && !aggregate.event) || (aggregate.sub_event === upshotEvent.subtype && getEventTypeForString(aggregate.event) === upshotEvent.type)) {
                if (aggregate.sub_event === upshotEvent.subtype) {
                    // check if event attribute contains value which is present in attribute_values

                    var foundAttribute = undefined;
                    var foundRelatedAttribute = undefined;
                    var evaluateBothAttributes = false;

                    if (aggregate['aggregate_type'] === 'attribute') {

                        if (aggregate.slidingWindow) {

                            if (aggregate.slidingType === 'days') {

                                if (!aggregate.dayCountMap) {
                                    aggregate.dayCountMap = {}
                                }

                                var t;

                                if (upshotEvent.startTime) {
                                    t = bkDate.getDay(upshotEvent.startTime)
                                } else {
                                    t = bkDate.utcToday().toString();
                                }

                                if (aggregate.attribute in upshotEvent.params) {

                                    switch (aggregate.operator) {
                                        case 'sum':

                                            if (!aggregate.dayCountMap[t]) {
                                                aggregate.dayCountMap[t] = 0;
                                            }

                                            aggregate.dayCountMap[t] += upshotEvent.params[aggregate.attribute];

                                            if (!aggregate.value) {
                                                aggregate.value = 0;
                                            }

                                            for (var key in aggregate.dayCountMap) {
                                                if (aggregate.dayCountMap.hasOwnProperty(key)) {

                                                    aggregate.value += aggregate.dayCountMap[key];

                                                }
                                            }


                                            break;
                                        default:

                                    }

                                    aggregatesMap.forEach(function (val, key){
                                        if (val['aggregate_type'] === 'Aggregates' && val['attribute'] === aggregate['id']) {
                                            val['value'] = aggregate['value'];
                                            val['dayCountMap'] = aggregate['dayCountMap'];
                                            rulesMap[val['ruleId']] = true;
                                        }
                                    })

                                    aggregate.ruleId = aggregate.id;

                                } else {
                                    continue;
                                }

                            }

                        }

                    }

                    if (aggregate.aggregate_type === "attributevalues") {
                        var att_operator = aggregate.attribute_operator;
                        if (!("attribute_operator" in aggregate) || (aggregate.attribute_operator === null)) {
                            att_operator = "eq";
                        }

                        var containsOperators = ['containsone', 'containsnone', 'containsall', 'between']

                        if (containsOperators.indexOf(aggregate.attribute_operator) !== -1) {
                            var attribute_value = aggregate.attribute_values
                            if (logicalOperator[att_operator](upshotEvent.params[aggregate.attribute], aggregate.attribute_values)) {
                                foundAttribute = attribute_value;
                            }
                        }else if ("params" in upshotEvent) {
                            for (var valueIndex = 0, vlen = aggregate.attribute_values.length; valueIndex < vlen; valueIndex++) {
                                var attribute_value = aggregate.attribute_values[valueIndex];

                                if (aggregate.event === "Instasense" && (aggregate.sub_event === 3 || aggregate.sub_event === 1)) {

                                    if (aggregate.sub_event === 1) {
                                        var major = {};
                                        upshotEvent.params.forEach(function (val, key){

                                            for (var ky in val) {
                                                if (val.hasOwnProperty(ky)) {
                                                    if (!major[ky]) {
                                                        major[ky] = '';
                                                    }

                                                    major[ky] += val[ky];
                                                }
                                            }
                                        })

                                        if (logicalOperator[att_operator](major[aggregate.attribute], attribute_value)) {
                                            foundAttribute = attribute_value;
                                            break;
                                        }
                                    } else if (aggregate.sub_event === 3) {
                                        upshotEvent.params.every(function (val, key){

                                            if (logicalOperator[att_operator](val[aggregate.attribute], attribute_value)) {
                                                foundAttribute = attribute_value;
                                                return false;
                                            } else {
                                                return true
                                            }
                                        })
                                        if (foundAttribute) {
                                            break;
                                        }
                                    }

                                } else {
                                    if (logicalOperator[att_operator](upshotEvent.params[aggregate.attribute], attribute_value)) {
                                        foundAttribute = attribute_value;
                                        break;
                                    }
                                }
                            }
                        }

                    }

                    if (aggregate.aggregate_type === "relatedattributevalues") {
                        evaluateBothAttributes = true;
                        var relatedatt_operator = aggregate.attribute_operator;
                        if (!("relatedattribute_operator" in aggregate) || (aggregate.relatedattribute_operator === null)) {
                            relatedatt_operator = "eq";
                        }
                        if ("params" in upshotEvent) {
                            for (var valueIndex = 0, vlen = aggregate.relatedattribute.length; valueIndex < vlen; valueIndex++) {
                                var relatedattribute_value = aggregate.relatedattribute_values[valueIndex];
                                if (logicalOperator[relatedatt_operator](upshotEvent.params[aggregate.attribute], relatedattribute_value)) { // should update logical operator based on the attribute logicalOperator
                                    foundRelatedAttribute = relatedattribute_value;
                                    break;
                                }
                            }
                        }
                    }


                    if (evaluateBothAttributes === true) { // if this true, foundAttribute and foundRelatedAttribute should not be empty
                        if (foundRelatedAttribute === undefined || foundAttribute === undefined) {
                            continue;
                        }
                    }

                    if (aggregate.slidingWindow && aggregate.aggregate_type !== 'attribute' && aggregate.aggregate_type !== 'Aggregates') {
                        //BK.log(" sliding window");
                        if (!("dayCountMap" in aggregate)) {
                            aggregate["dayCountMap"] = {};
                        }

                        var dayUtc = aggregate.slidingType === "days"
                            ? bkDate.utcToday().toString()
                            : aggregate.slidingType === "months"
                                ? bkDate.utcCurrentMonth().toString()
                                :
                                /* aggregate.slidingType==="years"? */
                                bkDate.utcCurrentYear.toString();

                        if (dayUtc in aggregate.dayCountMap) {
                            aggregate.dayCountMap[dayUtc] += 1;
                        } else {
                            aggregate.dayCountMap[dayUtc] = 1;
                        }
                    } else if (aggregate.aggregate_type === "attributevalues") {

                        if (!foundAttribute) {
                            aggregate.evaluated = false;
                            continue;
                        }

                        if (("isDummy" in aggregate) && aggregate.isDummy) {
                            // collect this aggregate in dummyAggretesList
                            dummyAggregates.push(aggregate.id);
                            // For instasense
                            if (aggregate.event === 'Instasense') {
                                aggregate.evaluated = true;
                            }
                        } else {
                            if (!("value" in aggregate)) {
                                aggregate["value"] = 1;
                            } else {
                                aggregate.value += 1;
                            }
                        }

                    } else if (aggregate.aggregate_type === "event") {

                        if (("isDummy" in aggregate) && aggregate.isDummy) {
                            // collect this aggregate in dummyAggretesList
                            dummyAggregates.push(aggregate.id);
                            // For instasense
                            if (aggregate.event === 'Instasense') {
                                aggregate.evaluated = true;
                            }
                        } else {
                            if (!("value" in aggregate)) {

                                aggregate["value"] = 1;
                            } else {
                                aggregate.value += 1;
                            }
                        }

                    } else if (aggregate.aggregate_type === "Location") {

                        if (BK.evaluateGeoLocation(upshotEvent.params,
                            {latitude:Number(aggregate.attribute_values[0]),longitude:Number(aggregate.attribute_values[1])},
                            Number(aggregate.attribute_values[2]),
                            aggregate.operator) === true) {

                                if (!("value" in aggregate)) {

                                    aggregate["value"] = 1;
                                } else {
                                    aggregate.value += 1;
                                }

                            } else {
                                continue;
                            }

                    }

                    aggregate.update_time = Math.floor(bkDate.utcNow() / 1000);
                    //BK.log("Update found Modfied date ");
                    rulesMap[aggregate.ruleId] = true; //FIXME
                }

            }

            var dataMap = {
                data: aggregatesMap,
                metadata: {
                    location: previousLocation,
                    pushRepeatCounts: pushRepeatCounts
                }
            }

            if (typeof aggregatesModifiedCallback === 'function') {
                aggregatesModifiedCallback(dataMap);
            }

            return rulesMap;
        }

        /**
         * evaluates given group filter and returns boolean
         */
        function evaluateGroupFilter(filterRef, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess) {

            var code = filterRef.code;
            var andCondition = (filterRef.condition === "and");
            var result = andCondition
                ? true
                : false;

            var len = filterRef.filters.length;
            for (var i = 0; i < len; i++) {
                var f = filterRef.filters[i];
                var r = evaluate(f, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess);

                if (andCondition) {
                    result = result && r;
                } else {
                    result = result || r;
                }

                // log("evaluateGroupFilter:"+filterRef.code+":"+r+"::"+result);

                if (andCondition !== result) {
                    break;
                }

            }

            return result;

        }

        function isValidOperands(v1, v2) {
            return v1 !== undefined && v2 !== undefined;
        }
        /**
         * logical operator methods [UTIL]
         */
        var logicalOperator = {

            "gt": function(v1, v2) {
                return isValidOperands(v1, v2) && v1 > v2;
            },
            "lt": function(v1, v2) {
                return isValidOperands(v1, v2) && v1 < v2;
            },
            "eq": function(v1, v2) {
                return isValidOperands(v1, v2) && v1 == v2;
            },
            "neq": function(v1, v2) {
                return isValidOperands(v1, v2) && v1 != v2;
            },
            "like": function(v1, v2) {
                return isValidOperands(v1, v2) && v1.indexOf(v2) != -1;
            },
            "nlike": function(v1, v2) {
              return isValidOperands(v1, v2) && v1.indexOf(v2) === -1;
            },
            "starts": function(v1, v2) {
                //polyfill for String.startswith
                if (!String.prototype.startsWith) {
                    String.prototype.startsWith = function(searchString, position) {
                        position = position || 0;
                        return this.substr(position, searchString.length) === searchString;
                    };
                }

                return isValidOperands(v1, v2) && v1.startsWith(v2);

            },
            "ends": function(v1, v2) {
                //polyfill for String.endsWith
                if (!String.prototype.endsWith) {
                    String.prototype.endsWith = function(searchString, position) {
                        var subjectString = this.toString();
                        if (typeof position !== 'number' || !isFinite(position) || Math.floor(position) !== position || position > subjectString.length) {
                            position = subjectString.length;
                        }
                        position -= searchString.length;
                        var lastIndex = subjectString.lastIndexOf(searchString, position);
                        return lastIndex !== -1 && lastIndex === position;
                    };
                }

                return isValidOperands(v1, v2) && v1.endsWith(v2);
            },
            "between": function (v1, v2){
                return isValidOperands(v1, v2) && (function (){
                    var found = false;

                    try {
                        if (Number(v1) > Number(v2[0]) && Number(v1) < Number(v2[1])) {
                            found = true;
                        }
                    } catch (e) {

                    }

                    return found;
                })()
            },
            "containsone": function (v1, v2){
                return isValidOperands(v1, v2) && (function (){
                    var found = false;

                    v2.every(function (val, key){

                        if (v1.toLowerCase().indexOf(val.toLowerCase()) !== -1) {
                            found = true;
                            keywords.push(val);
                            return false;
                        } else {
                            return true;
                        }

                    })
                    return found;
                })()
            },
            "containsnone": function (v1, v2){
                return isValidOperands(v1, v2) && (function (){
                    var found = false;

                    v2.every(function (val, key){

                        if (v1.toLowerCase().indexOf(val.toLowerCase()) !== -1) {
                            found = true;
                            keywords.push(val);
                            return false;
                        } else {
                            return true;
                        }

                    })
                    return !found;
                })()
            },
            "containsall": function (v1, v2){
                return isValidOperands(v1, v2) && (function (){
                    var found = true;

                    v2.every(function (val, key){

                        if (v1.toLowerCase().indexOf(val.toLowerCase()) === -1) {
                            found = false;
                            return false;
                        } else {
                            keywords.push(val);
                            return true;
                        }

                    })
                    return found;
                })()
            },
            'selected': function(v1, v2, qType, rating) {
                if (qType === 9 || qType === 7 || qType === 11) {
                    var result = false;
                    if (v1 === 'any') {
                        for (var key in v2) {
                            if (v2.hasOwnProperty(key)) {
                                if (v2[key] === rating) {
                                    result = true;
                                }
                            }
                        }

                        return result;
                    } else {
                        return isValidOperands(v1, v2) && (v1 in v2) && (v2[v1] === rating)
                    }
                } else {
                    return isValidOperands(v1, v2) && (v2.includes(v1))
                }

            },
            'notselected': function(v1, v2, qType, rating) {

                return !logicalOperator.selected(v1, v2, qType, rating)

            }
        }; //--logicalOperator--

        function evaluateXTPDAggExp(variable, dataProvider) {
            var result = true,
            data = dataProvider.dayCountMap;

            if (variable.subType === 'xt_pd') {
                for (var key in data) {
                    if (data.hasOwnProperty(key)) {

                        if (!logicalOperator[variable.operator](data[key], variable.values[0])) {
                            result = false;
                        }

                    }
                }
            }

            return result;
        }

        /**
         * evaluates aggregate expression and returns boolean, dataProvider has
         * to provide the required information.
         */
        function evaluateAggregateExpression(variables, dataProvider) {

            var result = false;

            // FIXME: should change this code as of now we are hardcoding
            // should

            var variable = undefined;
            for (var i = 0, len = variables.length; i < len; i++) {
                variable = variables[i];
                if ("key" in variable || 'date_range' in variable) {
                    break;
                }
            }

            if ('date_range' in variable) {
                result = evaluateXTPDAggExp(variable.date_range, dataProvider);
            } else {
                result = logicalOperator[variable.operator](dataProvider.value, variable.values[0]);
            }

            return result;

        }

        /**
         * evaluates UserProfile expression, dataProvider has to provide the
         * required information.
         */
        function evaluateUserProfileExpression(variables, dataProvider, isInboxFilter) {

            for (var i = 0, len = variables.length; i < len; i++) {
                var v = variables[i];

                if (v.key === "PushToken") {
                    if (v.operator === dataProvider[v.key]) {
                        return true;
                    }

                } else {
                    if (v.operator in logicalOperator) {

                        // if (isInboxFilter && v.key === 'Platform') {
                        //     if (dataProvider['Platform'] === 'Unity_iOS') {
                        //         dataProvider['Platform'] = 'iOS';
                        //     } else if (dataProvider['Platform'] === 'Unity_Android') {
                        //         dataProvider['Platform'] = 'Android';
                        //     }
                        // }

                        return logicalOperator[v.operator](dataProvider[v.key], v.values[0]);
                    } else {
                        // TODO
                        BK.log("operator '" + v.operator + "' not in util methods");
                    }
                }
            }
            return false;
        }

        /**
         * evaluates custom events based on provided variables
         */
        function evaluateCustomEvents(variables, dataProvider, filterCode, rule, expSubType) {

            var result = false;

            // FIXME: should change this code as of now we are hardcoding
            // should

            var variable = undefined;
            for (var i = 0, len = variables.length; i < len; i++) {
                variable = variables[i];
                if ("key" in variable) {
                    break;
                }
            }

            // if(dataProvider.)

            //BK.log("Variable ---- " + JSON.stringify(variable));
            if (variable.date_range.type === "xt_pd" || variable.date_range.type === "xt_n" || variable.date_range.type === "xt_pm") { // x times per day (XTPD)
                result = evaluateXTPDExpression(variable, dataProvider, filterCode, variables[1], rule, expSubType);
            } else {
                result = evaluateCustomKeyEvents(variable, dataProvider, filterCode, variables[1],
                /* second object in variables will be operation */
                rule, expSubType);
            }
            return result;
        }

        function evaluateResponse(variables, upshotEvent, qType) {
            var result = false;

            // FIXME: should change this code as of now we are hardcoding
            // should

            var variable = undefined;
            for (var i = 0, len = variables.length; i < len; i++) {
                variable = variables[i];
                if ("key" in variable) {
                    break;
                }
            }

            var responses = [];

            if (variable.key[0] === 'any' && !(qType === 9 || qType === 7 || qType === 11)) {

                if (variable.operator == 'selected' && upshotEvent.response.length > 0) {
                    nextQueId = variable.values;
                    return true;
                } else if(variable.operator == 'notselected' && upshotEvent.response.length === 0) {
                    nextQueId = variable.values;
                    return true;
                }
                return false;
            }

            if (qType === 1 && upshotEvent.explanation !== '') {
                responses.push('responded')
            } else if ((qType === 4 || qType === 8 || qType === 10 || qType == 15) && upshotEvent.response.length > 0) {
                responses.push(upshotEvent.response[0].explanation)
            } else {
                upshotEvent.response.forEach(function (val, key){

                    if (qType === 9 || qType === 7 || qType === 11) {
                        var res = {}
                        responses[val.option_id] = val.explanation
                    } else if (val.option_id) {
                        responses.push(val.option_id)
                    }
                })
            }

            var present = true
            variable.key.every(function (v, k){
                if (!logicalOperator[variable.operator](v, responses, qType, variable.rating)) {
                    present = false;
                    return false;
                } else {
                    return true;
                }
            })

            if (present) {
                result = true;
                nextQueId = variable.values;
            }

            return result;
        }

        /**
         * Evaluates single-filter, and returns boolean.
         * filterRef is used to parse filter Object
         * ruleId is used to map which rule is being executed
         */
        function evaluateSingleFilter(filterRef, rule, upshotEvent, dummyAggregates, isInboxFilter, onSuccess) {

            var expression = filterRef.expression;
            var result = false;

            // FIXME move the 'dataProvider' from here, hardcoded for testing
            // purpose.

            if (expression.type === "Aggregates") {

                var aggId = rule.codes[filterRef.code];
                var matchedAggregate = undefined;
                for (var index = 0, ilen = aggregatesMap.length; index < ilen; index++) {
                    var aggregatex = aggregatesMap[index];
                    if (aggregatex.id === aggId) {
                        matchedAggregate = aggregatex;
                        break;
                    }
                }

                result = evaluateAggregateExpression(expression.variable, matchedAggregate)
            } else if (expression.type === "UserProfile") {
                result = evaluateUserProfileExpression(expression.variable, upshotEvent, isInboxFilter);
            } else if ((getEventTypeForString(expression.type) === 8 || getEventTypeForString(expression.type) === 10) && expression.event !== 106) {

                // data provider will be fetched from aggregate

                // parsing hidden Aggregate to update meta info

                var aggId = rule.codes[filterRef.code];
                var matchedAggregate = undefined;
                for (var index = 0, ilen = aggregatesMap.length; index < ilen; index++) {
                    var aggregatex = aggregatesMap[index];
                    if (aggregatex.id === aggId) {
                        matchedAggregate = aggregatex;
                        break;
                    }
                }

                if (matchedAggregate.isDummy) {
                    if (matchedAggregate.event === 'Instasense') {
                        result = matchedAggregate.evaluated ? matchedAggregate.evaluated : false;
                    } else {
                        result = dummyAggregates.indexOf(matchedAggregate.id) != -1;
                    }
                } else {
                    result = evaluateCustomEvents(expression.variable, matchedAggregate, filterRef.code, rule, expression.event);
                }

            } else if (expression.type === 'Location' || expression.event === 106) {
                var aggId = rule.codes[filterRef.code];
                var matchedAggregate = undefined;
                for (var index = 0, ilen = aggregatesMap.length; index < ilen; index++) {
                    var aggregatex = aggregatesMap[index];
                    if (aggregatex.id === aggId) {
                        matchedAggregate = aggregatex;
                        break;
                    }
                }

                result = evaluateGeoExpression(expression, matchedAggregate);
            } else if (expression.type === 'Survey') {
                if (expression.event === upshotEvent.question_id) {
                    result = evaluateResponse(expression.variable, upshotEvent, expression.qType);
                }
            } else if (expression.type === 'PreDefinedEvents' && expression.event === 'Sessions') {

                var time = expression.variable[0].values[0]
                time = time - upshotEvent.timer > 0 ? time - upshotEvent.timer : 0

                if (time === 0) {
                    result = true;
                }
            }

            return result;

        }

        function evaluateGeoExpression(expression, matchedAggregate) {

            var location = {
                latitude : Number(expression.variable[0].lat),
                longitude : Number(expression.variable[0].long)
            }

            if (typeof matchedAggregate == 'undefined') {
                // console.log('No matchedAggregate found for give location');
                return false;
            }

            return matchedAggregate.value > 0;
        }

        function evaluateCustomKeyEvents(variable, dataProvider, filterCode, operationVariable, rule, expSubType) {
            // find aggregate for this expression/singleFilter

            if (dataProvider === undefined) {
                BK.log("Aggregate not found for filter:" + filterCode + " in rule:" + rule.id);
                return false;
            }

            var found = false;

            if (operationVariable !== undefined) {
                if (operationVariable.operator === "occurence" && variable.key === dataProvider.attribute && dataProvider.attribute_values.indexOf(variable.value) > -1) {
                    found = true;

                } else if (variable.key === dataProvider.attribute) {

                    if ((typeof variable.value === 'object' && JSON.stringify(dataProvider.attribute_values) == JSON.stringify(variable.value)) || (dataProvider.attribute_values.indexOf(variable.value) > -1)) {
                        if (operationVariable.operator in logicalOperator) {
                            found = logicalOperator[operationVariable.operator](dataProvider.value, operationVariable.value);
                        } else {
                            BK.log("invalid operator:" + operationVariable.operator + " in rule:" + rule.id);
                        }
                    }


                } else if (variable.key === "occurs") {
                    if (variable.operator in logicalOperator) {
                        found = logicalOperator[variable.operator](dataProvider.value, variable.value);
                    } else {
                        BK.log("invalid operator:" + operationVariable.operator + " in rule:" + rule.id);
                    }

                } else if (variable.key === "occurence" && dataProvider.sub_event == expSubType) { // FIXME: as of now we are sending it blindly we need check with event subtype also
                    found = true;
                }
            } else {
                if (variable.key === "occurs" && dataProvider.sub_event == expSubType) {
                    if (variable.operator in logicalOperator) {
                        found = logicalOperator[variable.operator](dataProvider.value, parseInt(variable.value));
                    } else {
                        BK.log("invalid operator:" + operationVariable.operator + " in rule:" + rule.id);
                    }

                } else if (variable.key === dataProvider.attribute && dataProvider.attribute_values.indexOf(variable.value) > -1) {
                    found = true;
                }
            }

            //  check if this contains rhs_filters if has rhs_filters update the rhs count
            // var rhsFilters = foundRule.filter.filters[0].rhs_filters;
            // if (rhsFilters.length > 0 && found) {
            //     if (!("rhs" in dataProvider)) {
            //         dataProvider["rhs"] = 0;
            //     } else {
            //         dataProvider.rhs += 1;
            //     }
            //
            //     found = false;
            //
            //     if (rhsFilters[0] == dataProvider.rhs) {
            //         found = true;
            //     }
            // }

            return found;
        }

        /**
         * last n days :: last 2 days (current day and yesterday)
         * last m months :: last 2 months( current month and previous month)
         * last y years ;: last 2 yesrs ( current year and previous year)
         */
        function getLastNUtc(type, n) {

            if (n < 1) {
                throw "input should be >=1 ::" + type + ":" + n;
            }

            var dayUtc = new Date();
            if (type === "years") {
                return Date.UTC(dayUtc.getUTCFullYear() - (n - 1), 0, 1, 0, 0, 0, 0);
            }

            if (type === "months") {

                var yr = dayUtc.getUTCFullYear() - (n / 12);
                n = n % 12; // n [0, 11]

                var m = 0;

                var currentMonth = dayUtc.getUTCMonth();

                if ((n - 1) > currentMonth) {
                    yr = yr - 1;
                    m = (currentMonth + 12) - (n - 1);
                } else {
                    m = currentMonth - (n - 1);
                }

                return Date.UTC(yr, m, 1, 0, 0, 0, 0);

            }

            if (type === "days") {
                return bkDate.utcToday() - (86400000 * (n - 1));
            }

        }

        /**
         * Evaluates `x times per day` expression, and return metaInfo
         */
        function evaluateXTPDExpression(variable, dataProvider, filterCode, operationVariable, rule, expSubType) {

            if (dataProvider === undefined) {
                //FIXME ????
                return false;
            }

            // ------------------------
            var subEventType = parseInt(dataProvider.sub_event);

            if (subEventType == expSubType) {

                var dayCountMap = dataProvider.dayCountMap;

                // processed aggregate and its
                // metadata, now have to check
                // expression

                var days = Object.keys(dayCountMap);

                var todayUtc = bkDate.utcToday();
                var givenDaysCount = parseInt(variable.date_range.values[0])/* [0] in xt_pd indicates number of days */;
                var lastNdayUtc = getLastNUtc(dataProvider.slidingType, givenDaysCount);

                var requiredDayUtcs = [];
                for (var day in dayCountMap) {
                    var dayNum = parseInt(day);

                    if (lastNdayUtc <= dayNum && dayNum <= todayUtc) {
                        requiredDayUtcs.push(dayNum);
                    }
                }

                // Existing version

                // if (requiredDayUtcs.length === givenDaysCount) {
                //     var i = 0;
                //     if (variable.date_range.type === "xt_n") {
                //         var totalCount = 0;
                //
                //         for (; i < requiredDayUtcs.length; i++) {
                //             var day = requiredDayUtcs[i];
                //
                //             totalCount += dayCountMap[day];
                //
                //         }
                //
                //         var logicalResult = logicalOperator[variable.date_range.operator](totalCount, parseInt(variable.date_range.values[1])/* 1 indicates days */);
                //
                //         return logicalResult;
                //     } else {
                //
                //         for (; i < requiredDayUtcs.length; i++) {
                //             var day = requiredDayUtcs[i];
                //
                //             if (variable.date_range.operator in logicalOperator) {
                //
                //                 var logicalResult = logicalOperator[variable.date_range.operator](dayCountMap[day], parseInt(variable.date_range.values[1])/* 1 indicates days */);
                //
                //                 if (!logicalResult) { // failure case
                //                     break;
                //                 }
                //
                //             } else {
                //                 // TODO
                //                 BK.log("operator '" + variable.operator + "' not in util methods");
                //             }
                //
                //         }
                //         if (i == givenDaysCount) {
                //             // check if there is any operation variable
                //             //FIXME return aggregates here...
                //             return true;
                //         }
                //     }
                // }

                // WIP version

                var i = 0;
                if (variable.date_range.type === "xt_pd" && variable.date_range.subType === 'ntimes') {
                    var totalCount = 0;

                    for (; i < requiredDayUtcs.length; i++) {
                        var day = requiredDayUtcs[i];

                        totalCount += dayCountMap[day];

                    }

                    var logicalResult = logicalOperator[variable.date_range.operator](totalCount, parseInt(variable.date_range.values[1])/* 1 indicates days */);

                    return logicalResult;
                } else if (variable.date_range.type === "xt_pd" && variable.date_range.subType !== 'ntimes' && requiredDayUtcs.length === givenDaysCount) {

                    for (; i < requiredDayUtcs.length; i++) {
                        var day = requiredDayUtcs[i];

                        if (variable.date_range.operator in logicalOperator) {

                            var logicalResult = logicalOperator[variable.date_range.operator](dayCountMap[day], parseInt(variable.date_range.values[1])/* 1 indicates days */);

                            if (!logicalResult) { // failure case
                                break;
                            }

                        } else {
                            // TODO
                            BK.log("operator '" + variable.operator + "' not in util methods");
                        }

                    }
                    if (i == givenDaysCount) {
                        // check if there is any operation variable
                        //FIXME return aggregates here...
                        return true;
                    }
                }

                // WIP end


            }
            return false;
        }
        // writing to file
        /** setCurrentPlatform has to be defined before prepareAggregateMap.
         **/
        BK.setCurrentPlatform = function(platform) {
            return BK_PLATFORM = platform;
        };

        /**
         * Loads given rules
         */
        BK.loadRules = function(rulesJsonString) {

            BK.log("Rules Parsing Started");

            var parsedJSON = JSON.parse(rulesJsonString);

            rules = parsedJSON;

            BK.log("Parsing Completed");

            rules.forEach(function (val, key){
                if (val.filter.type === 'group') {
                    val.filter.filters.forEach(function (v1, k1) {
                        if (v1.type === 'group') {
                            v1.filters.forEach(function (v2, k2){
                                if (v2.type === 'single' && v2.expression.event === 'Sessions') {
                                    timers.push(v2.expression.variable[0].values[0])
                                }
                            })
                        }
                    })
                }
            })

            if (rules) {
                return true;
            }
            return false;
        };

        function getRE(rule) {

            var RE = [];

            function group(filter) {
                filter.filters.forEach(function (val, key){
                    evalIS(val);
                })
            }

            function single(expression) {
                if (expression.type === 'Instasense' && expression.event !== 5 && expression.event <100) {
                    var re = {
                        event: 10,
                        subEvent: expression.event,
                        type: null,
                        customDate: null,
                        ruleId: rule.id
                    }

                    if (expression.event === 3) {
                        var found = false;
                        re.type = 'date';
                        expression.variable.forEach(function (val, key){
                            if (val.type === 'date') {
                                found = true;
                                if (val.date_range.type === 'nextxdays') {
                                    re.customDate = new Date(new Date().getTime() + new Date().getTimezoneOffset() + 86400000*val.date_range.values[0]).setHours(23,59,59,999);
                                } else {
                                    re.customDate = new Date(Number(val.date_range.values[1])+(new Date()).getTimezoneOffset()).setHours(23,59,59,999);
                                }
                            }
                        })

                        if (!found) {
                            re.customDate = new Date(new Date(new Date().getTime()+(new Date()).getTimezoneOffset()).setMonth(new Date().getMonth()+3)).setHours(23,59,59,999)
                        }
                    }

                    return re;
                }
            }

            function evalIS(filter) {
                if (filter.type === 'group') {
                    group(filter);
                } else if (filter.type === 'single') {
                    var re = single(filter.expression);
                    if (re) {
                        RE.push(re);
                    }
                }
            }

            evalIS(rule.filter);

            return RE;

        }

        BK.getRelatedEvents = function (){
            var relatedEvents = [];

            rules.forEach(function (val, key){
                if (val.instasense) {
                    relatedEvents = relatedEvents.concat(getRE(val));
                }
            })

            return relatedEvents;
        }

        BK.processRelatedEvents = function (re, reCallback){
            var RE = {};

            re = JSON.parse(re);

            if (re.length > 0) {
                re.forEach(function (val, key){
                    RE[val.ruleId] = val;
                    BK.processEvent(JSON.stringify(val), reCallback);
                })

            }

        }

        var pushInboxNotifications = [],
            pushRuleIds = [],
            pushCampaignIds = [];

        BK.processInbox = function(inboxJSONString, payloadJSONString) {
            var inbox = JSON.parse(inboxJSONString);
            var payload = JSON.parse(payloadJSONString);
            payload.AppVersion = payload.appVersion;

            var filteredInbox = [];

            for (var index in inbox) {
                if (inbox.hasOwnProperty(index)) {
                    var message = inbox[index];

                    if (message.customData.bk.activity[0].type === 6) {
                        pushInboxNotifications.push(inbox[index]);
                        pushRuleIds.push(inbox[index].customData.bk.ruleId);
                        pushCampaignIds.push(message.customData.bk.campaignId);
                        continue;
                    }

                    BK.log("Parsing messageID :" + message.msgId);
                    // check if message contains filter ?
                    var filter = message.filter;
                    if (filter) {
                        var result = evaluate(filter, undefined, payload, undefined, true);
                        if (result == false) {
                            BK.log("Removed MessageID" + message.msgId);
                        } else {
                            filteredInbox.push(inbox[index]);
                        }
                    } else {
                        filteredInbox.push(inbox[index]);
                    }
                }
            }

            return filteredInbox;
        };

        var surveyRule = [],
        nextQueId,
        elseFilters = {};
        BK.setSurveyRules = function(sr) {
            surveyRule = JSON.parse(sr)

            surveyRule.filters.forEach(function (val, key){
                elseFilters[val.qId] = val.else_filters.values
            })
        }

        BK.evaluateSurveyResponse = function(res) {
            res = JSON.parse(res)
            // console.log(res);
            var result = evaluate(surveyRule, undefined, res);

            if (result) {
                return nextQueId;
            } else if (elseFilters[res.question_id]) {
                return elseFilters[res.question_id]
            }

        }

        /**
         * Processes give event and responds through provided onSuccess
         * callaback with an appropriate action.
         */

        var currentLocation;
        var timers = []

        BK.processEvent = function(eventJsonString, onSuccess, instasenseCallback) {
            BK.log("processing event... ");

            var upshotEvent = JSON.parse(eventJsonString);
            //Location instasense event
            if (upshotEvent.type === 10 && upshotEvent.subtype === 106) {
                upshotEvent.type = 4;
                upshotEvent.subtype = 191;
            }

            var dummyAggregates = [];
            var rulesMap = evaluateAggreate(upshotEvent, dummyAggregates);

            currentLocation = upshotEvent.type === 4
                ? upshotEvent.params
                : undefined;

            for (var i = 0; i < rules.length; i++) {

                var rule = rules[i];

                var isAgg = false;

                for (var key in rule.codes) {
                    var aid = rule.codes[key];
                    if (aid in rulesMap) {
                        isAgg = true;
                    }
                }

                if (!(rule.id in rulesMap) && !isAgg) {
                    // rule.id is not in rulesMap
                    continue;
                }

                if (false) {
                    instasenseCallback(getRE(rule))
                }

                // evaluating current event related rule...

                var ruleEvaluated = evaluate(rule.filter, rule, upshotEvent, dummyAggregates, undefined, onSuccess);

                if (upshotEvent.type === 4) {
                    previousLocation = upshotEvent.params;
                }

                if (typeof onSuccess === "function") {
                    if (ruleEvaluated) {
                        BK.log("Executed Rule for Name " + rule.name);
                        if (pushRuleIds.indexOf(rule.id) !== -1) {
                            pushInboxNotifications.forEach(function(val, key) {

                                if (val.customData.bk.ruleId === rule.id) {
                                    if (pushRepeatCounts[val.customData.bk.campaignId] > 0) {
                                        rule.notification = undefined;
                                        return;
                                    } else {
                                        pushRepeatCounts[val.customData.bk.campaignId] = 1;
                                    }

                                    var payloadData = val.customData.bk.activity[0].data,
                                    appData = val.customData.app;

                                    if (BK_PLATFORM === "iOS" || BK_PLATFORM === "Unity_iOS") {

                                        var iOSPayload = {
                                            "aps": {
                                                "alert": {}
                                            },
                                            "appData": {},
                                            "bk_mdata": {}
                                        }

                                        appData.forEach(function (val1, key1){
                                            iOSPayload.appData[val1.key] = val1.ios_value
                                        })

                                        iOSPayload.aps.alert.title = payloadData.ios_title ? payloadData.ios_title: '';
                                        iOSPayload.aps.alert.subtitle = payloadData.ios_sub_title ? payloadData.ios_sub_title: '';
                                        iOSPayload.aps.alert.body = payloadData.message ? payloadData.message: '';
                                        iOSPayload.aps.badge = payloadData.badge ? payloadData.badge: '';
                                        iOSPayload.aps.category = payloadData.iosCategory ? payloadData.iosCategory : '';
                                        iOSPayload.aps.sound = payloadData.sound ? payloadData.sound: '';
                                        iOSPayload.bk = val.msgId;
                                        iOSPayload.bk_mdata.cid = val.customData.bk.campaignId;
                                        iOSPayload.bk_mdata.msgId = val.msgId;
                                        // FIXME hardcoded here. Change after payload updates.
                                        iOSPayload.bk_mdata.activity = true;
                                        iOSPayload.bk_mdata.isLocal = true;


                                        rule.notification = iOSPayload;
                                    } else if (BK_PLATFORM === "Android" || BK_PLATFORM === "Unity_Android") {

                                        var AndroidPayload = {
                                            "appData": {}
                                        }

                                        appData.forEach(function (val1, key1){
                                            AndroidPayload.appData[val1.key] = val1.ios_value
                                        })
                                        AndroidPayload.bk = val.msgId;
                                        AndroidPayload.alert = payloadData.message ? payloadData.message : '';
                                        AndroidPayload.sound = payloadData.sound ? payloadData.sound : '';
                                        AndroidPayload.title = payloadData.title ? payloadData.title : '';
                                        AndroidPayload.fileName = payloadData.fileName ? payloadData.fileName : '';
                                        AndroidPayload.bundle_url = payloadData.bundle_url ? payloadData.bundle_url : '';
                                        AndroidPayload.isLocal = true;

                                        rule.notification = AndroidPayload;
                                    }
                                }
                            })
                        }
                        // rule.notification = BK_PLATFORM;
                        onSuccess(rule.id, rule.name, rule.notification, JSON.stringify(keywords));

                    }
                } else if (typeof onSuccess !== 'undefined') {
                    BK.log("callback 'onSuccess' should be a function.");
                }

                var dataMap = {
                    data: aggregatesMap,
                    metadata: {
                        location: previousLocation,
                        pushRepeatCounts: pushRepeatCounts
                    }
                }
                aggregatesModifiedCallback(dataMap);

            }

            if (upshotEvent.subtype === 'Sessions') {
                var nextTimer = getLatestTimer(upshotEvent.timer)
                onSuccess(undefined, undefined, undefined, undefined, nextTimer)
            }

            if (upshotEvent.type === 4) {
                previousLocation = upshotEvent.params;
            }

            var dataMap = {
                data: aggregatesMap,
                metadata: {
                    location: previousLocation,
                    pushRepeatCounts: pushRepeatCounts
                }
            }


            if (typeof aggregatesModifiedCallback === 'function') {
                aggregatesModifiedCallback(dataMap);
            }
        };

        function getLatestTimer(time) {
            timers.sort(function(a, b){return a - b})

            var result = 0

            timers.every(function (val, key){
                if (val - time > 0) {
                    result = val - time
                    return false;
                } else {
                    return true;
                }
            })

            return result;
        }

        var syncAggregateValues = function(serverMap, localMap) {

            if (localMap.length == 0) {
                return;
            }

            var sValues = serverMap;
            var lValues = localMap;

            // s = server
            // l = local

            for (var sIndex = 0; sIndex < sValues.length; sIndex++) {
                var sValue = sValues[sIndex];
                // changed
                // var serverAggId = sValue.aggregate_id;
                var serverAggId = sValue.id;
                var serverUpdatedTime = sValue.update_time;

                for (var lIndex = 0; lIndex < lValues.length; lIndex++) {
                    var lValue = lValues[lIndex];
                    var localUpdatedTime = lValue.update_time;
                    // check agg Id
                    // changed
                    // if (serverAggId === lValue.aggregate_id) {
                    if (serverAggId === lValue.id) {
                        // check server Updated Time with local Updated Time
                        if (typeof serverUpdatedTime === 'undefined' || localUpdatedTime >= serverUpdatedTime) {
                            //if that object contains dayCountMap ? update dayCountMap
                            if ("dayCountMap" in sValue) {
                                sValue["dayCountMap"] = lValue.dayCountMap;
                            } else if ("value" in sValue) { // if that object contains value ? update value
                                sValue["value"] = lValue.value;
                            }
                        }
                        break;
                    }
                }

            }

        }
        var previousLocation;
        BK.prepareAggregateMap = function(aggregateValues, aggregateDefinitions, localAggregateMap, onAggregatesModified) {
            if (localAggregateMap.hasOwnProperty('data')) {
                if (localAggregateMap.metadata.hasOwnProperty('location')) {
                    previousLocation = localAggregateMap.metadata.location;
                }

                // Delete the campaign repeat counts which are inactive
                if (localAggregateMap.metadata.hasOwnProperty('pushRepeatCounts')) {
                    pushRepeatCounts = localAggregateMap.metadata.pushRepeatCounts;
                    for (var key in pushRepeatCounts) {
                        if (pushRepeatCounts.hasOwnProperty(key)) {
                            if (pushCampaignIds.indexOf(key) === -1) {
                                delete pushRepeatCounts[key];
                            }
                        }
                    }
                }

                // console.log(pushRepeatCounts);

                localAggregateMap = localAggregateMap.data;
            }

            if (typeof BK_PLATFORM === 'undefined') {
                BK.log("call setCurrentPlatform(string) to set the current platform");
                return;
            }

            aggregatesModifiedCallback = onAggregatesModified; // FIXME: only send modified aggregate

            var aggregateMap = [];

            // ----
            for (var defIndex = 0, defLen = aggregateDefinitions.length; defIndex < defLen; defIndex++) {
                var aggDef = aggregateDefinitions[defIndex];

                var relatedAggregateValueFound = false;
                for (var valIndex = 0, valLen = aggregateValues.length; valIndex < valLen; valIndex++) {
                    var aggVal = aggregateValues[valIndex];

                    if (aggVal.aggregate_id == aggDef.id) {
                        relatedAggregateValueFound = true;
                        //

                        if ("value" in aggVal) {
                            aggDef["value"] = aggVal.value;
                        }
                        if ("dayCountMap" in aggVal) {
                            aggDef["dayCountMap"] = aggVal.dayCountMap;

                            //
                            //
                            if (aggDef.slidingType === "months") {
                                var curentMonthStr = bkDate.utcCurrentMonth().toString();
                                if (!(curentMonthStr in aggDef["dayCountMap"])) {
                                    aggDef["dayCountMap"][curentMonthStr] = 0;
                                }

                            } else { // days
                                var curentDayStr = bkDate.utcToday().toString();
                                if (!(curentDayStr in aggDef["dayCountMap"])) {
                                    aggDef["dayCountMap"][curentDayStr] = 0;
                                }
                            }

                        }
                        if ("update_time" in aggVal) {
                            aggDef["update_time"] = aggVal.update_time;
                        }

                        if (!("platform" in aggDef)) {
                            //platform is not there in aggDef.
                            aggDef["platform"] = 'all'; // default is 'all'
                        }

                        aggregateMap.push(aggDef);
                    }

                }

                if (!relatedAggregateValueFound) { // aggregate value not found for current aggregate def
                    //

                    if (aggDef.slidingWindow && !("dayCountMap" in aggDef)) {
                        aggDef["dayCountMap"] = {}; // default value

                        if (aggDef.slidingType === "months") {
                            aggDef["dayCountMap"][bkDate.utcCurrentMonth().toString()] = 0;
                        } else { // days
                            aggDef["dayCountMap"][bkDate.utcToday().toString()] = 0;
                        }

                    } else {
                        aggDef.value = 0; // default value
                    }

                    if (!("platform" in aggDef)) {
                        //platform is not there in aggDef.
                        aggDef["platform"] = 'all'; // default is 'all'
                    }

                    aggregateMap.push(aggDef);

                }

            }

            aggregatesMap = aggregateMap;
            syncAggregateValues(aggregatesMap, localAggregateMap);

            var dataMap = {
                data: aggregatesMap,
                metadata: {
                    location: previousLocation,
                    pushRepeatCounts: pushRepeatCounts
                }
            }

            aggregatesModifiedCallback(dataMap);

            //BK.log("AggregateMAP ====== " + JSON.stringify(aggregatesMap));
        };

        function writeFile(filePath, content) {
            // var fs = require('fs');
            // fs.writeFile(filePath, JSON.stringify(content, null, 4), function(err) {
            //     if (err) {
            //         return console.log(err);
            //     }
            //
            //     console.log("The file was saved!");
            // });

        }
        // Function for using geo fencing
        // checkpoint is the current location, centerPoint is reference point
        BK.evaluateGeoLocation = function(checkpoint, centerPoint, radius, operator) {

            var ky = 40000000 / 360,
                kx = Math.cos(Math.PI * centerPoint.latitude / 180.0) * ky,
                dx = Math.abs(centerPoint.longitude - checkpoint.longitude) * kx,
                dy = Math.abs(centerPoint.latitude - checkpoint.latitude) * ky;
            // console.log(Math.sqrt(dx * dx + dy * dy));

            switch (operator) {
                case 'Enters':
                    if (typeof previousLocation === 'undefined' || BK.evaluateGeoLocation(previousLocation, centerPoint, radius, 'checkEnter')) {
                        // previousLocation = checkpoint;
                        return Math.sqrt(dx * dx + dy * dy) <= radius;
                    } else {
                        // previousLocation = checkpoint;
                        return false;
                    }
                    break;
                case 'Exits':
                    if (typeof previousLocation === 'undefined') {
                        return false;
                    } else if (BK.evaluateGeoLocation(previousLocation, centerPoint, radius, 'checkExit')) {
                        // previousLocation = checkpoint;
                        return Math.sqrt(dx * dx + dy * dy) > radius;
                    } else {
                        // previousLocation = checkpoint;
                        return false;
                    }
                    break;
                case 'checkEnter':
                    // return Math.sqrt(dx * dx + dy * dy) > radius;
                    return true;
                    break;
                case 'checkExit':
                    return Math.sqrt(dx * dx + dy * dy) <= radius;
                    break;
            }
        }

        /**
         * Shuts down the bk engine.
         */
        BK.shutdown = function(force) {

            // Pre ES2015,
            force = typeof force !== 'undefined'
                ? force
                : false;

            BK.log("shutting down engine, force:" + force);

        };

        return BK;
    }

    // initialize bk engine
    if (typeof($BK$) === 'undefined') {
        $BK$ = define_library();
    } else {
        $BK$.log("BK library already defined");
    }

})();

//TODO comment the module.exoports in production
module.exports = $BK$;
