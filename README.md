## Prerequisity

 * `gem install gooddata`
    * to install the GoodData Ruby gem
 * `goodata auth:store` 
    * to save your GoodData credentials in the ~/.gooddata file (caution: the credentials are stored without any encryption)

## Usage

`./assign_filter.rb project_id email label_idtf value`

`./invite_with_filter.rb project_id email label_idtf value`

*Example:*

`./permissions.rb d01480a4d1807af40a5d45cf57347041 joe@example.com label.department.id Accounting`

`./invite_with_filter.rb d01480a4d1807af40a5d45cf57347041 joe@example.com /gdc/projects/d01480a4d1807af40a5d45cf57347041/roles/5 label.department.id Accounting`

 * project_id - project ID, e.g. d01480a4d1807af40a5d45cf57347041
 * email      - specifies the user whose permissions are restricted
 * role       - a URI of the role of the invited user
 * label_idtf - the identifier of the label used in the data access
                filtering expression.
                If the corresponding column in the XML data set
                descriptor has ldmType 'ATTRIBUTE' and name 'xyz' and
                the schema name is 'dataset', use 'label.dataset.xyz'.
                If the column is a label named 'xyz' pointing to the
                attribute 'abc', use 'label.dataset.abc.xyz' instead.
 * value      - the value of label_idtf that can identify rows
                accessible by the user

