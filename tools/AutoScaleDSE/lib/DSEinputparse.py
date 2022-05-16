import os
import shutil
import copy
import re
import subprocess
import re
import copy
import treelib

c_keywords = ["auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while"]
c_vars = ["char", "double", "float", "int", "short"]

class ROI(object):
         def __init__(self, input):
             self.group = input

class ArrayP(object):
         def __init__(self, count=0, type=None, factor=None, dim=None):
             self.count = count
             self.type = type
             self.factor = factor
             self.dim = dim

def int_to_alpha(input):
    output = ''
    alphabet = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']
    while True:
        if input - 26 < 0:
            output = output + alphabet[input]
            break
        else:
            output = output + 'z'
            input = input - 26
    return output

def add_node(tree, input):
    try:
        tree.create_node("Loop" + str(input[1]), int(input[1]), parent=input[0])
    except:
        pass

    sub_l0 = re.findall(r'\d+', str(input[2]))
    # test for single loop
    if int(sub_l0[0]) != int(input[1]):
        try:
            tree.create_node("Loop" + str(sub_l0[0]), int(sub_l0[0]), parent=int(input[1]))
        except:
            pass
        for i in range(1, len(sub_l0)):
            try:
                tree.create_node("Loop" + str(sub_l0[i]), int(sub_l0[i]), parent=int(sub_l0[i-1]))
            except:
                pass

def recur_add_subtree(mastertree, toptree, treelist, function_depend):
    functioncall_order = 0
    DFS_list = [toptree[node] for node in toptree.expand_tree(mode=treelib.Tree.DEPTH, sorting=False)]
    for DFS_node in DFS_list: #DFS search
        for depend_node in function_depend: #find children tress
            isordered = re.findall(r'(.+)-', DFS_node.tag)
            if isordered: #to match with renamed tags
                functionname = re.findall(r'-(.+)', DFS_node.tag)
            else:
                functionname = [DFS_node.tag]
            if functionname[0] == str(depend_node[1]):
                for treeinlist in treelist: #find subtree
                    if treeinlist[treeinlist.root].tag == depend_node[0]:
                        UID_count = 1
                        duplicate_list = [mastertree[node].tag for node in mastertree.expand_tree(mode=treelib.Tree.DEPTH, sorting=False)]
                        for i in range(len(duplicate_list)):
                            isordered = re.findall(r'(.+-)', duplicate_list[i])
                            if isordered: #to match with renamed tags
                                re_buffer = re.findall(r'-(.+)', duplicate_list[i])
                                duplicate_list[i] = re_buffer[0]
                        for dnode in duplicate_list:
                            if dnode == depend_node[0]:
                                UID_count += 1

                        #rebuild tree / change UID
                        addtree = treelib.Tree()
                        for node in treeinlist.expand_tree(mode=treelib.Tree.DEPTH, sorting=False):
                            if treeinlist[node].is_root():
                                addtree.create_node(int_to_alpha(functioncall_order) + "-" + treeinlist[node].tag, str(treeinlist[node].identifier) + "-" + str(UID_count))
                                functioncall_order += 1
                            else:
                                parent_uid = str(treeinlist.parent(treeinlist[node].identifier).identifier)
                                addtree.create_node(treeinlist[node].tag, str(treeinlist[node].identifier) +  "-" + str(UID_count), parent=(parent_uid +  "-" + str(UID_count)))

                        mastertree.paste(DFS_node.identifier, addtree, deep=False) 
                        recur_add_subtree(mastertree, addtree, treelist, function_depend)

def read_user_input():
    default_file_flag = False
    inputfiles = []
    with open("ML_userinput.txt", 'r') as file:
        for line in file:
            if re.findall(r'^(\s)*#', line):
                None
            elif re.findall(r'target_source_file_location', line):
                source_file_raw = re.findall(r'=(.+)', line)
                source_file = source_file_raw[0].strip()
                #print(source_file)
            elif re.findall(r'top_function', line):
                inputtop_raw = re.findall(r'=(.+)', line)
                inputtop = inputtop_raw[0].strip()
                #print(inputtop)
            elif re.findall(r'part(\s)?=', line):
                inputpart_raw = re.findall(r'=(.+)', line)
                inputpart = inputpart_raw[0].strip()
                #print(inputpart)
            elif re.findall(r'add_files', line):
                if line.strip() == "add_files default":
                    inputfiles = ["add_files ../ML_in.cpp\n"]
                    default_file_flag = True
                else:
                    if default_file_flag == False:
                        inputfiles.append(line)
    file.close()    
    template = read_template()
    return source_file, inputtop, inputpart, inputfiles, template

def read_template():
    template = []
    tempstart = False
    with open("ML_userinput.txt", 'r') as file:
        for line in file:
            if tempstart:
                template.append(line)
            if re.findall(r'#template', line):
                tempstart = True
    file.close()
    return template

def get_dependent_arrays(var_arraylist_sized):
    multiloop_arrays = []
    for arr in var_arraylist_sized :
        # get number of dependencies / start from end
        numentr = len(arr)
        for deploc in range(len(arr) - 1, -1, -1):
            if arr[deploc] == 'dependencies':
                if numentr > deploc + 2:
                    multiloop_arrays.append(arr)

    return multiloop_arrays

def read_sdse_arrpart(sdsefile, topfuntion):
    in_pattern = False
    brace_count = 0

    function_passed_val = []
    function_declared_val = []
    # get local array partition scheme
    with open(sdsefile, 'r') as file:
        for line in file:

            #scope finder
            if brace_count == 0: 
                raw_scope = re.findall(r'(void|char|double|float|int|short)\s([A-Za-z_]+[A-Za-z_\d]*)(\s)?(\()', line)
                if raw_scope:
                    scope = raw_scope[0][1]
                    if scope == topfuntion:
                        in_pattern = True                        

            if(re.findall('{', line)):
                brace_count += 1

            if(re.findall('}', line)):
                if brace_count == 1:
                    in_pattern = False
                    brace_count -= 1
                else:
                    brace_count -= 1

            # get sdse array partition scheme
            if re.findall("#pragma HLS array_partition", line):
                part_var = re.findall(r'variable\s?=\s?([A-Za-z_]+[A-Za-z_\d]*)\s', line)
                part_scheme = re.findall(r'(cyclic|block|complete)', line)
                part_factor = re.findall(r'factor\s?=\s?(\d+)\s', line)
                part_dim = re.findall(r'dim\s?=\s?(\d+)\s?', line)
                
                # store scheme in list
                for item in function_passed_val:
                    if part_var[0] == item[1]:
                        item.append(part_scheme[0])
                        item.append(part_factor[0])
                        item.append(part_dim[0])
                for item in function_declared_val:
                    if part_var[0] == item[1]:
                        item.append(part_scheme[0])
                        item.append(part_factor[0])
                        item.append(part_dim[0])

            # if in_pattern and brace_count > 0:
            if in_pattern and brace_count == 0:
                arr2part = re.findall(r'(int|float|double)\s([A-Za-z_]+[A-Za-z_\d]*)\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])+(,|;|\)|' ')', line)
                if(arr2part):
                    for item in arr2part:
                        function_passed_val.append([scope, item[1]])                            
            elif in_pattern and brace_count > 0:
                arr2part = re.findall(r'(int|float|double)\s([A-Za-z_]+[A-Za-z_\d]*)\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])+(,|;|\)|' ')', line)
                if(arr2part):
                    for item in arr2part:
                        current_array = "".join(item[1:-1])
                        array_sizeofdim = re.findall(r'\[(.+?)\]', current_array)
                        array_dim = len(array_sizeofdim)
                        # do not capture scalehls auto gen arrays which are a dummy array of dim1 size1
                        if not(array_dim < 2 and int(array_sizeofdim[0]) < 2):
                            function_declared_val.append([scope, item[1]])
    file.close()

    # 1st dim stores passed values second dim stores non passed values
    sdse_var_part = [topfuntion, function_passed_val, function_declared_val]

    return sdse_var_part


def create_params(dir, var_forlist, var_arraylist_sized):
    paramfile = open (dir + "/ML_params.csv", 'w')
    paramfile.write("type,name,scope,range,dim\n")
    for item in var_forlist :
        if item == "":
            None
        elif re.findall(r'U+', item[0]):
            paramfile.write("loopU,"+str(item[0])+','+str(item[2])+','+str(item[3])+"\n")
        else:
            paramfile.write("loop,"+str(item[0])+','+str(item[2])+','+str(item[3])+"\n")
    #array
    for item in var_arraylist_sized :
        if item:
            name0 = re.findall(r'(.+?)\[', item[1])
            if item[4] > 1:
                for i in range(int(item[4])):
                    paramfile.write("array,"+str(item[2])+','+str(item[3])+','+str(item[5+i])+','+str(1+i)+"\n")
            else:
                paramfile.write("array,"+str(item[2])+','+str(item[3])+','+str(item[5])+','+str(item[4])+"\n")
    paramfile.close()
    return 0

def create_template(dir, sourcefile, inputfiles, template):
    templatefile = open (dir + "/ML_template.txt", 'w')
    templatefile.write("open_project {{ project_name }}\n")
    templatefile.write("set_top {{ top_function }}\n")
    if inputfiles:
        for item in inputfiles:
            templatefile.write(item)
    else:
        templatefile.write("add_files "+str(sourcefile)+"\n")
    for item in template:
        templatefile.write(item)
    return 0

def preproccess(tar_dir, source_file, dsespec, inputtop):

    #scalehls dse temp directory
    sdse_dir = tar_dir + "/scalehls_dse_temp/"
    if not(os.path.exists(sdse_dir)):
        os.makedirs(sdse_dir)

    # copy due to linux ownership
    inputfile = "scalehls_in.c"
    sdse_input_file_loc = sdse_dir + inputfile
    if not(os.path.exists(sdse_input_file_loc)):        
        shutil.copy(source_file, sdse_input_file_loc)

    os.chdir(sdse_dir)

    p1 = subprocess.Popen(['mlir-clang', inputfile, '-function=' + inputtop, '-memref-fullrank', '-raise-scf-to-affine', '-S'],
                            stdout=subprocess.PIPE)                           

    with open('preprocessing.cpp', 'wb') as fout:
        subprocess.run(['scalehls-translate', '-emit-hlscpp'], stdin=p1.stdout, stdout=fout)

    var_forlist_tree = []
    var_forlist_tree_popped = []
    var_func_names = []
    function_depend = []
    loopnum = 0
    brace_cout = 0
    popped = False
    is_brace = False
    scope = None

    var_forlist = []

    #get loop bounds
    with open('preprocessing.cpp', 'r') as file:        
        for line in file:
            is_brace = False

            #find function calls
            if brace_cout >= 1:
                functioncall = re.findall(r'\s([A-Za-z_]+[A-Za-z_\d]*)\s?\(', line)
                if functioncall:
                    for item in functioncall:
                        if item in var_func_names:
                            if len(var_forlist_tree) > 0:
                                function_depend.append((item, "Loop" + str(var_forlist_tree[-1][0])))
                            else:
                                function_depend.append((item, scope))

            #scope finder
            if brace_cout == 0: 
                raw_scope = re.findall(r'((void|int|float))\s([A-Za-z_]+[A-Za-z_\d]*)(\s)?(\()', line)
                if raw_scope:
                    scope = raw_scope[0][2]
                    var_func_names.append(scope)

            if(re.findall('{', line)):
                is_brace = True
                if brace_cout == 0:
                    brace_cout += 1
                else:
                    brace_cout += 1
                
                #for band
                if len(var_forlist_tree) > 0 and var_forlist_tree[-1][1] == None:
                    var_forlist_tree[-1][1] = brace_cout

            if(re.findall('}', line)):
                #function scope
                if brace_cout == 1:
                    scope = None
                    brace_cout -= 1
                else:
                    brace_cout -= 1

                if len(var_forlist_tree) > 0 and var_forlist_tree[-1][1] == brace_cout:
                    var_forlist_tree_popped.append(var_forlist_tree.pop())
                    popped = True
                
                if len(var_forlist_tree) == 0 and len(var_forlist_tree_popped) > 0:
                    subtree = ""
                    if len(var_forlist_tree_popped) == 1:
                        subtree = "-" + str(var_forlist_tree_popped[0][0])
                    else:
                        for i in range(len(var_forlist_tree_popped) - 2, -1, -1):
                            subtree = subtree + "-" + str(var_forlist_tree_popped[i][0])

                    var_forlist_tree = []
                    var_forlist_tree_popped = []
                    popped = False

            # todo: temp measure -> implement using MLIR IR
            # change int32_t to int
            elif(re.findall('for', line)): #find loops // only supports one forloop per line
                if not(re.findall(r'(.)*(//)(.)*(for)(.)*', line)): # ignore for in comment
                    #save scoped list if start new for loop band
                    if popped:
                        subtree = ""
                        for i in range(len(var_forlist_tree) - 1, 0, -1):
                            var_forlist_tree_popped.append(var_forlist_tree[i])
                        for i in range(len(var_forlist_tree_popped) - 1, -1, -1):
                            subtree = subtree + "-" + str(var_forlist_tree_popped[i][0])

                        var_forlist_tree_popped = []
                        popped = False

                    if is_brace:
                        var_forlist_tree.append((loopnum, brace_cout - 1))
                    else:
                        var_forlist_tree.append((loopnum, brace_cout))

                    
                    findbound = re.findall(r'(<|>|<=|>=)(.+?);', line) #find bound
                    findbound = findbound[0][1].strip()                    
                    #cheak if bound is evaluable
                    evaluable_chars = ['+', '-', '*', '/', '(', ')', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
                    can_eval = False
                    for char in findbound:
                        if char in evaluable_chars:
                            can_eval = True
                        else:
                            can_eval = False
                    
                    if can_eval: # test if variable bound
                        forbound = str(eval(findbound))
                    else:                        
                        forbound = 'Variable'
                    var_forlist.append(list(("Loop"+str(loopnum), line.strip(), scope, forbound)))
                    loopnum += 1

    max_loop_bound = -1
    for item in var_forlist :
        if item[-1].isnumeric and max_loop_bound < int(item[-1]):
            max_loop_bound = int(item[-1]) 

    # unrolling loops beyond 256 leads to non-viable designs
    if max_loop_bound > 256:
        max_loop_bound = 256

    refactored_config = copy.deepcopy(dsespec) 
    refactored_config['max_init_parallel'] = int(max_loop_bound)
    refactored_config['max_expl_parallel'] = int(max_loop_bound * 1.5)
    refactored_config['max_loop_parallel'] = int(max_loop_bound / 3)
    refactored_config['max_iter_num'] = int(max_loop_bound / 3)
    refactored_config['max_distance'] = int(max_loop_bound / 14)
    # with open('config.json', 'w') as f:
    #     json.dump(refactored_config, f)

    os.chdir("../..")

    return refactored_config

def process_source_file(dir, inputfile, outfile, topfun, sdse=False, sdse_arr=False):
    
    var_forlist_tree = []
    var_forlist_tree_popped = []
    var_func_names = []
    function_depend = []
    loopnum = 0
    arraynum = 0
    brace_cout = 0
    loopband_hotness = 0
    popped = False
    is_brace = False
    scope = None


    var_forlist = []
    var_arraylist_sized = []
    var_forlist_scoped = []

    newfile = open (dir + outfile, 'w')
    with open(inputfile, 'r') as file:        
        for line in file:
            is_brace = False

            #find function calls
            if brace_cout >= 1:
                functioncall = re.findall(r'\s([A-Za-z_]+[A-Za-z_\d]*)\s?\(', line)
                if functioncall:
                    for item in functioncall:
                        if item in var_func_names:
                            if len(var_forlist_tree) > 0:
                                function_depend.append((item, "Loop" + str(var_forlist_tree[-1][0])))
                            else:
                                function_depend.append((item, scope))

            #scope finder
            if brace_cout == 0: 
                raw_scope = re.findall(r'((void|int|float))\s([A-Za-z_]+[A-Za-z_\d]*)(\s)?(\()', line)
                if raw_scope:
                    scope = raw_scope[0][2]
                    var_func_names.append(scope)

            if(re.findall('{', line)):
                is_brace = True
                if brace_cout == 0:
                    brace_cout += 1
                else:
                    brace_cout += 1
                
                #for band
                if len(var_forlist_tree) > 0 and var_forlist_tree[-1][1] == None:
                    var_forlist_tree[-1][1] = brace_cout

            if(re.findall('}', line)):
                #function scope
                if brace_cout == 1:
                    scope = None
                    var_forlist.append("")
                    var_arraylist_sized.append("")
                    var_forlist_scoped.append("")
                    brace_cout -= 1
                else:
                    brace_cout -= 1

                if len(var_forlist_tree) > 0 and var_forlist_tree[-1][1] == brace_cout:
                    var_forlist_tree_popped.append(var_forlist_tree.pop())
                    popped = True
                
                if len(var_forlist_tree) == 0 and len(var_forlist_tree_popped) > 0:
                    subtree = ""
                    if len(var_forlist_tree_popped) == 1:
                        subtree = "-" + str(var_forlist_tree_popped[0][0])
                    else:
                        for i in range(len(var_forlist_tree_popped) - 2, -1, -1):
                            subtree = subtree + "-" + str(var_forlist_tree_popped[i][0])

                    var_forlist_scoped.append((scope, var_forlist_tree_popped[-1][0], subtree, loopband_hotness))
                    # var_forlist_scoped.append((scope, var_forlist_tree_popped[-1][0], var_forlist_tree_popped[0][0], loopband_hotness))
                    var_forlist_tree = []
                    var_forlist_tree_popped = []
                    loopband_hotness = 0
                    popped = False

            # temp measure
            if(re.findall(r'^(\s)*#include', line)): #ignore #include
                None
                newfile.write(line)
            elif(re.findall(r'^(\s)*#pragma', line)): #ignore #pragma
                if ((re.findall(r'^(\s)*#pragma HLS pipeline II', line)) and (sdse)):
                    newfile.write(line)
                    # newfile.write("#pragma HLS pipeline\n")
                elif ((re.findall(r'^(\s)*#pragma HLS array_partition', line)) and (sdse_arr)):
                    newfile.write(line)
                else: 
                    None
            elif(re.findall(r'using namespace std;', line)): #ignore #pragma
                None
            # todo: temp measure -> implement using MLIR IR
            # change int32_t to int
            elif(re.findall('int32_t', line)):
                newfile.write(re.sub('int32_t', 'int', line))
            elif(re.findall('for', line)): #find loops // only supports one forloop per line
                if not(re.findall(r'(.)*(//)(.)*(for)(.)*', line)): # ignore for in comment
                    #save scoped list if start new for loop band
                    if popped:
                        subtree = ""
                        for i in range(len(var_forlist_tree) - 1, 0, -1):
                            var_forlist_tree_popped.append(var_forlist_tree[i])
                        for i in range(len(var_forlist_tree_popped) - 1, -1, -1):
                            subtree = subtree + "-" + str(var_forlist_tree_popped[i][0])

                        var_forlist_scoped.append((scope, var_forlist_tree[0][0], subtree, loopband_hotness))
                        # var_forlist_scoped.append((scope, var_forlist_tree[0][0], var_forlist_tree_popped[0][0], loopband_hotness))                        
                        var_forlist_tree_popped = []
                        loopband_hotness = 0
                        popped = False

                    if is_brace:
                        var_forlist_tree.append((loopnum, brace_cout - 1))
                    else:
                        var_forlist_tree.append((loopnum, brace_cout))

                    
                    findbound = re.findall(r'(<|>|<=|>=)(.+?);', line) #find bound
                    findbound = findbound[0][1].strip()                    
                    #cheak if bound is evaluable
                    evaluable_chars = ['+', '-', '*', '/', '(', ')', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
                    can_eval = False
                    for char in findbound:
                        if char in evaluable_chars:
                            can_eval = True
                        else:
                            can_eval = False
                    
                    if can_eval: # test if variable bound
                        forbound = str(eval(findbound))
                    else:                        
                        forbound = 'Variable'
                    var_forlist.append(list(("Loop"+str(loopnum), line.strip(), scope, forbound)))
                    newfile.write(line.replace("for", "Loop" + str(loopnum)  + ": " + "for"))
                    loopnum += 1
                else: # copy other
                    newfile.write(line)
            else: # copy other
                newfile.write(line)

            #find array
            #only upto six dimentions
            arr2part = re.findall(r'(int|float|double)\s([A-Za-z_]+[A-Za-z_\d]*)\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])+(,|;|\)|' ')', line)
            if(arr2part and brace_cout < 2): #do not add arrays instantiated within loops
                for item in arr2part:
                    current_array = "".join(item[1:-1])
                    array_sizeofdim = re.findall(r'(\[)(.+?)(\])', current_array)
                    array_dim = len(array_sizeofdim)
                    list_buffer = list(("Array"+str(arraynum), current_array, item[1], scope, array_dim))
                    for cdim in array_sizeofdim:
                        list_buffer.append(cdim[1])
                    list_buffer.append("dependencies")
                    var_arraylist_sized.append(list_buffer)
                    arraynum += 1

            #dependency search
            if len(var_forlist_tree) > 0: 
                line_array_list = re.findall(r'\s([A-Za-z_]+[A-Za-z_\d]*)\s?\[', line)
                if var_arraylist_sized and line_array_list:
                    for item_list_array in var_arraylist_sized :
                        if item_list_array == "":
                            None
                        else:
                            for item_line_array in line_array_list:
                                if item_list_array[2] == item_line_array:
                                    #ignore if already in list    
                                    # dep_state = re.findall(r'(\d)array', item_list_array[0])
                                    if(type(item_list_array[-1]) ==  "dependencies"): # if first entry
                                        item_list_array.append(var_forlist_tree[0][0])
                                    elif item_list_array[-1] == var_forlist_tree[0][0]: #check for conflicts
                                        None
                                    else:
                                        item_list_array.append(var_forlist_tree[0][0])

            #hotloop counter
            if len(var_forlist_tree) > 0:
                num_mul = 0
                num_div = 0
                num_add = 0
                num_min = 0
                if not(re.findall('for', line)):
                    #do not count address calculations as calculations
                    # remove_address_cal = re.findall(r'([^[\]]+)(?:$|\[)', line)
                    # clean_line = " ".join(remove_address_cal)

                    nub_mul_raw = re.findall(r'\*', line)
                    nub_div_raw = re.findall(r'\/', line)
                    nub_add_raw = re.findall(r'\+', line)
                    nub_min_raw = re.findall(r'\-', line)
                    num_mul = len(nub_mul_raw)
                    num_div = len(nub_div_raw)
                    num_add = len(nub_add_raw)
                    num_min = len(nub_min_raw)

                line_trip_count = 1
                if(num_mul + num_div + num_add + num_min) > 0:
                    for asso_loop in var_forlist_tree:
                        for loopdirectory in var_forlist:
                            if loopdirectory == "":
                                None
                            else:
                                if loopdirectory[-1] == 'Variable':
                                    # line_trip_count = 0
                                    # should be break but is none due to breaking when variable loops exist in list
                                    None
                                else:
                                    loc_loopnum = re.findall(r'\d+', loopdirectory[0])
                                    if int(loc_loopnum[0]) == asso_loop[0]:
                                        line_trip_count *= int(loopdirectory[-1])
                    loopband_hotness += line_trip_count * (4 * (num_mul + num_div) + num_add + num_min) #weight for mul and addition
    file.close()
    newfile.close()

    #add outer most loop for loops with more than one nested loop band
    if sdse:
        var_forlist_buffer = []
        for i in range(len(var_forlist_scoped) - 2):
            if var_forlist_scoped[i][1] == var_forlist_scoped[i+1][1]:
                imm_parent = var_forlist_scoped[i][1]
                #find immidiate parent
                a = re.findall(r'\d+', var_forlist_scoped[i][2])
                b = re.findall(r'\d+', var_forlist_scoped[i+1][2])
                try:
                    for i in range(len(a) - 2, -1, -1):
                        for j in range(len(b) - 2, -1, -1):
                            if int(a[i]) == int(b[j]):
                                imm_parent = int(b[j])
                                raise StopIteration
                except StopIteration: 
                    pass
                
                #find parent loop in for list
                for loopdirectory in var_forlist:
                    if loopdirectory != "":
                        loc_loopnum = re.findall(r'\d+', loopdirectory[0])
                        if int(loc_loopnum[0]) == int(imm_parent):
                            if len(var_forlist_buffer) > 0:
                                if var_forlist_buffer[-1][0] != loopdirectory[0]:
                                    var_forlist_buffer.append(loopdirectory)
                            else:
                                var_forlist_buffer.append(loopdirectory)
        var_forlist = copy.deepcopy(var_forlist_buffer)
        # mark loop
        # for item in var_forlist:
        #     item[0] = item[0] + "U"

    # create tree
    tree_list = []
    if len(var_forlist_scoped) > 1: 
        StartofTree = True
        tree = None
        for i in range(len(var_forlist_scoped)):
            if var_forlist_scoped[i] == "":
                StartofTree = True
            else:
                if StartofTree:
                    tree = treelib.Tree()                    
                    tree_list.append(tree)
                    tree.create_node(str(var_forlist_scoped[i][0]), str(var_forlist_scoped[i][0]))  # root node
                    add_node(tree, var_forlist_scoped[i])
                    StartofTree = False
                else:
                    add_node(tree, var_forlist_scoped[i])

        #check if top fucntion in tree
        is_in_tree_list = []
        for func in var_func_names:
            is_in = False
            for tree in tree_list:    
                if tree.root == func:
                    is_in = True
            is_in_tree_list.append(is_in)

        for i in range(len(is_in_tree_list)):
            if is_in_tree_list[i]:
                None
            else:
                tree = treelib.Tree()
                tree.create_node(var_func_names[i], var_func_names[i])
                tree_list.insert(i, tree)

        #create master tree
        #todo: not capable of adding more that one funtion to tree
        for tree in tree_list:
            if tree.root == topfun:
                mastertree = treelib.Tree(tree.subtree(topfun), deep=True)
                recur_add_subtree(mastertree, mastertree, tree_list, function_depend)

        #add ROI datastructure
        DFS_list = [mastertree[node] for node in mastertree.expand_tree(mode=treelib.Tree.DEPTH, sorting=False)]
        for node in DFS_list:
            mastertree[node.identifier].data = ROI("None")
        # mastertree.show(data_property="group")

        tree_list.append(mastertree)
    
    return var_func_names, var_forlist, var_arraylist_sized, var_forlist_scoped, tree_list

def remove_multiloop_arrays_sdse_parti(dir, inputfile, var_arraylist_sized):

    # store multilooop array names
    mullooparrs = []
    for arr in var_arraylist_sized:
        mullooparrs.append(arr[2])

    with open (dir + inputfile, 'r+') as file:
        fileInmem = file.readlines()
        file.seek(0)
        for line in fileInmem:
            if re.findall('#pragma HLS array_partition', line):
                part_var = re.findall(r'variable\s?=\s?([A-Za-z_]+[A-Za-z_\d]*)\s', line)
                if not(part_var[0] in mullooparrs):
                    file.write(line)
            else:
                    file.write(line)
        file.truncate()



def asdse_get_knobs(inputfile, topfun, sdse_var_part_list):

    in_pattern = False
    line_break = False

    brace_count = 0
    arraynum = 0

    var_arraylist_sized = []
    function_pass_var_list = []

    with open(inputfile, 'r') as file:
        for line in file:

            #scope finder
            if brace_count == 0: 
                raw_scope = re.findall(r'(void|char|double|float|int|short)\s([A-Za-z_]+[A-Za-z_\d]*)(\s)?(\()', line)
                if raw_scope:
                    scope = raw_scope[0][1]
                    if scope == topfun:
                        in_pattern = True                        

            if(re.findall('{', line)):
                brace_count += 1

            if(re.findall('}', line)):
                if brace_count == 1:
                    in_pattern = False
                    brace_count -= 1
                else:
                    brace_count -= 1

            # if in_pattern and brace_count > 0:
            if in_pattern:
                arr2part = re.findall(r'(int|float|double)\s([A-Za-z_]+[A-Za-z_\d]*)\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])?\s?(\[.+\])+(,|;|\)|' ')', line)
                if(arr2part):
                    for item in arr2part:
                        current_array = "".join(item[1:-1])
                        array_sizeofdim = re.findall(r'\[(.+?)\]', current_array)
                        array_dim = len(array_sizeofdim)
                        list_buffer = list(("Array"+str(arraynum), current_array, item[1], scope, array_dim))
                        for cdim in array_sizeofdim:
                            val_eval = eval(cdim)
                            list_buffer.append(val_eval)
                        var_arraylist_sized.append(list_buffer)
                        arraynum += 1

            # find function calls -> can support line breaks
            line_function_call = re.findall(r'\s?([A-Za-z_]+[A-Za-z_\d]*\s?\(.*)', line)
            if in_pattern and (brace_count > 0) and (line_function_call or line_break):
                keyword = None
                if not(line_break):
                    keyword = re.findall(r'([A-Za-z_]+[A-Za-z_\d]*)\s?\(', line)
                    keyword = keyword[0].strip()

                if not(keyword in c_keywords) or line_break: #ignore c keywords
                    # get variables
                    raw_variables = re.findall(r'[A-Za-z_]+[A-Za-z_\d]*', line)
                    # print(raw_variables)

                    # only store arrays
                    if keyword != None:
                        function_pass_buf = [keyword]
                    
                    for var_pass in raw_variables:
                        for var_dec in var_arraylist_sized:
                            if var_dec[2] == var_pass:
                                function_pass_buf.append(var_pass)

                    # if line break should capture next line
                    if re.findall(';', line):
                        line_break = False
                        function_pass_var_list.append(function_pass_buf)
                    else:
                        line_break = True
                    # if line_break and len(re.findall(';', line)) > 0 :
                    #     line_break = False
                    #     function_pass_var_list.append(function_pass_buf)
    file.close()

    # print("local")
    # for item in sdse_var_part_list:
    #     print(item)
        
    # create array tree
    array_tree_list = []
    for top_call in function_pass_var_list:
        function_name = top_call[0]

        # find stored location of sdse local variable names
        for sdse_func in sdse_var_part_list:
            if sdse_func[0] == function_name:
                sdse_func_inq = sdse_func

        for i in range(1, len(top_call)):
            array_inq = top_call[i]
            array_tree = None
            # find array tree if it already exists
            for tree in array_tree_list:
                if array_inq == tree[tree.root].tag:
                    array_tree = tree

            # create tree if not in tree list
            if array_tree == None:
                array_tree = treelib.Tree()
                array_tree.create_node(tag=array_inq, identifier=array_inq, data=ArrayP(1))
                array_tree_list.append(array_tree)

            # only add to tree if sdse outputs an array partition scheme
            j = i -1
            if len(sdse_func_inq[1][j]) > 2:
                # function call name
                parent_iden = function_name + '-' + str(array_tree[array_tree.root].data.count)
                array_tree.create_node(tag=function_name, identifier=parent_iden, parent=array_inq, data=ArrayP())
                array_tree[array_tree.root].data.count += 1
                # add local variable name -> partition scheme stored as data
                array_tree.create_node(tag=sdse_func_inq[1][j][1], identifier=sdse_func_inq[1][j][1] + '-' + str(array_tree[array_tree.root].data.count), parent=parent_iden,
                                        data=ArrayP(0, sdse_func_inq[1][j][2], sdse_func_inq[1][j][3], sdse_func_inq[1][j][4]))
                array_tree[array_tree.root].data.count += 1

    # print("array trees")
    # count = 0
    # for item in array_tree_list:
    #     item.show(idhidden=False)
    #     item.show(data_property="dim")
    #     count += 1
    # print(count)
    
    return var_arraylist_sized, array_tree_list
    
