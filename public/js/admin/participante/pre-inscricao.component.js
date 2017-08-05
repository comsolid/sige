$(function () {
    moment.lang('pt-br');
    function debounce(fn, delay) {
        var timeoutID = null
        return function() {
            clearTimeout(timeoutID)
            var args = arguments
            var that = this
            timeoutID = setTimeout(function() {
                fn.apply(that, args)
            }, delay)
        }
    }

    Vue.filter('fromNow', function (value) {
        if (!value) return '';
        value = value.toString();
        return moment(value, 'YYYY-MM-DD HH:mm:ss.SSSS').fromNow();
    });

    var jed = {};
    function installJed(Vue, options) {
        Vue.prototype.$t = function (text) {
            return _(text);
        }
    }
    jed.install = installJed;
    Vue.use(jed);

    var bus = new Vue();

    var busca = {
        template: '#participante-busca',
        name: 'participante-busca',
        props: {
            isLoading: {
                type: Boolean,
                default: false
            }
        },
        data: function() {
            return {
                form: {
                    termo: '',
                    buscar_por: 'nome'
                }
            };
        },
        mounted: function () {
            bus.$on('clear-form-busca', function () {
                this.form.termo = '';
                this.$refs.termo.focus();
            }.bind(this));
        },
        methods: {
            buscar: function() {
                this.$emit('buscar', this.form);
            }
        },
        watch: {
            'form.termo': debounce(function(newVal) {
                this.$emit('buscar', this.form);
            }, 500),
            'form.buscar_por': function () {
                this.$refs.termo.focus();
                this.$emit('buscar', this.form);
            }
        }
    };
    var item = {
        template: '#participante-item',
        name: 'participante-item',
        props: {
            item: {
                type: Object,
                required: true
            },
            index: {
                type: Number,
                required: true
            }
        },
        data: function () {
            return {
                button: {
                    text: '',
                    icon: ''
                },
                label: {
                    text: '',
                    kind: ''
                },
                box: {
                    kind: ''
                },
                isSaving: false
            };
        },
        mounted: function () {
            this.updateStatus();
        },
        methods: {
            updateStatus: function () {
                if (this.item.cadastro_validado) {
                    this.label.text = this.$t('Validated registration');
                    this.label.kind = 'label-success';
                    this.box.kind = 'box-success';
                } else {
                    this.label.text = this.$t('Registration not validated yet');
                    this.label.kind = 'label-danger';
                    this.box.kind = 'box-danger';
                }
            },
            changeStatus: function () {
                var vm = this;
                vm.isSaving = true;
                vm.$parent.$emit('changeStatus', vm.index, vm.item, function () {
                    vm.isSaving = false;
                });
            }
        },
        watch: {
            'item.confirmado': function (newValue, oldValue) {
                this.updateStatus();
            }
        }
    };
    var lista = {
        template: '#participante-lista',
        name: 'participante-lista',
        props: {
            lista: {
                type: Array,
                required: true
            }
        },
        components: {
            'participante-item': item
        }
    };

    var index = new Vue({
        el: '#pre-inscricao-app',
        template: '#template-pre-inscricao',
        components: {
            'participante-busca': busca,
            'participante-lista': lista
        },
        data: {
            busca: {
                isLoading: false
            },
            lista: []
        },
        mounted: function() {
            this.buscar();
        },
        methods: {
            buscar: function(params) {
                var vm = this;
                vm.busca.isLoading = true;
                var promise = $.ajax({
                    url: '/admin/participante/ajax-buscar-nao-inscritos/',
                    type: 'POST',
                    data: $.extend({
                        format: 'json'
                    }, params)
                });
                promise.done(function(json) {
                    if (json.lista) {
                        vm.lista = json.lista;
                    }
                });
                promise.fail(function(jqXHR, textStatus, errorThrown) {
                    alertify.error(textStatus + ':' + errorThrown);
                });
                promise.always(function() {
                    vm.busca.isLoading = false;
                });
            },
            changeStatus: function (index, pessoa, onFinished) {
                var vm = this;
                var url = '/u/inscrever-confirmar/' + pessoa.id;
                var params = {
        			format: 'json'
        		};
                $.getJSON(url, params, function(json) {
        			if (json.ok) {
        				alertify.success(json.msg);
                        setTimeout(function () {
                            // vm.buscar();
                            bus.$emit('clear-form-busca');
                        }, 1000);
        			} else if (json.erro !== null) {
        				alertify.error(json.erro);
        			}
        		}).complete(function () {
        			onFinished();
        		});
            }
        }
    });
});
