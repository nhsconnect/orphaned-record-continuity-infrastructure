import os
import re

import yaml


class Configuration:
    path_matcher = re.compile(r'(.*)\$\{([^}^{]+)\}')

    def __init__(self, configuration_filename):
        self.load_configuration_file(configuration_filename)

    def yaml_constructor_for_environment_variables(self, loader, node):
        """ Extract the matched value, expand env variable, and replace the match """
        value = node.value
        match = self.path_matcher.match(value)
        return match.group(1) + os.environ.get(match.group(2)) + value[match.end():]

    def load_configuration_file(self, configuration_filename):
        yaml.SafeLoader.add_implicit_resolver('!path', self.path_matcher, None)
        yaml.SafeLoader.add_constructor('!path', self.yaml_constructor_for_environment_variables)

        with open(configuration_filename, 'r') as ymlfile:
            self.cfg = yaml.load(ymlfile, Loader=yaml.SafeLoader)

    def get_environment(self):
        return self.cfg['environment']

    def get_account_id(self):
        return self.cfg['account_id']

    def get_report_output_location(self):
        return self.cfg['cur_output_location']

    def get_glue_db(self):
        return self.cfg['cur_db']

    def get_glue_table(self):
        return self.cfg['cur_table']

    def get_cur_report_name(self):
        return self.cfg['cur_report_name']

    def get_region(self):
        region = os.environ.get('REGION')
        if not region:
            region = self.cfg['region']
        return region

    def get_sender_email_ssm_parameter(self):
        return self.cfg['sender_email_ssm_parameter']

    def get_recipient_email_ssm_parameter(self):
        return self.cfg['recipient_email_ssm_parameter']

    def get_support_email_ssm_parameter(self):
        return self.cfg['support_email_ssm_parameter']

    def get_athena_queries(self):
        return self.cfg['query_string_list']

    def get_generate_report_for_year(self):
        return self.cfg['generate_report_for_year']

    def get_generate_report_for_month(self):
        return self.cfg['generate_report_for_month']
