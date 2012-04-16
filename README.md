## Prerequisity

`gem install gooddata`

## Usage

`./permissions.rb project_id email label_idtf value`

*Example:*

`./permissions.rb d01480a4d1807af40a5d45cf57347041 joe@example.com label.department.id Accounting`

 * project_id - project ID, e.g. d01480a4d1807af40a5d45cf57347041
 * email      - specifies the user whose permissions are restricted
 * label_idtf - the identifier of the label used in the data access
                filtering expression.
                If the corresponding column in the XML data set
                descriptor has ldmType 'ATTRIBUTE' and name 'xyz' and
                the schema name is 'dataset', use 'label.dataset.xyz'.
                If the column is a label named 'xyz' pointing to the
                attribute 'abc', use 'label.dataset.abc.xyz' instead.
 * value      - the value of label_idtf that can identify rows
                accessible by the user

